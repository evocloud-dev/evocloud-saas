package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapMaintenanceShellInit: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-maintenance-shell-init"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"entrypoint.sh": """
			#!/usr/bin/env bash
			set -euo pipefail
			
			# Ensure we have the tools we need:
			# - util-linux: su with --whitelist-environment
			# - bash/coreutils: for arrays, comm, sort, etc.
			# - sudo/acl
			export DEBIAN_FRONTEND=noninteractive
			apt-get update
			apt-get install -y --no-install-recommends \\
				bash coreutils procps util-linux sudo acl yq mariadb-client \\
				\(#config.maintenance.shell.installPackages)
			# rm -rf /var/lib/apt/lists/*
			
			maintainer_group_name=\(#config.maintenance.shell.maintainer.groupName)
			maintainer_group_id=\(#config.maintenance.shell.maintainer.groupId)
			maintainer_user_name=\(#config.maintenance.shell.maintainer.userName)
			maintainer_user_id=\(#config.maintenance.shell.maintainer.userId)
			
			if ! getent group "$maintainer_group_name" >/dev/null; then
				addgroup --gid "$maintainer_group_id" "$maintainer_group_name"
				echo "%$maintainer_group_name ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
			fi
			
			if ! id -u "$maintainer_user_name" >/dev/null 2>&1; then
				adduser --disabled-password --gecos "" --uid "$maintainer_user_id" --gid "$maintainer_group_id" "$maintainer_user_name"
			fi
			
			home="$(eval echo ~"$maintainer_user_name")"
			
			# Minimal login customizations for the maintainer
			if ! grep -q 'PIMCORE_LOGIN_BOOTSTRAP' "$home/.profile" 2>/dev/null; then
				printf '%s\\n' \\
					'# PIMCORE_LOGIN_BOOTSTRAP' \\
					'export PHP_MAX_EXECUTION_TIME=0' \\
					'export PHP_MEMORY_LIMIT=-1' \\
					'target_dir=${MAINTAINER_CWD:-/var/www/pimcore}' \\
					'if [ -d "$target_dir" ]; then' \\
					'  cd "$target_dir" || true' \\
					'fi' >>"$home/.profile"
				chown "$maintainer_user_name:$maintainer_group_name" "$home/.profile"
			fi
			
			# Install helper scripts into PATH (copied from configmap mount)
			install -m 0755 /opt/maintenance-scripts/maint-login-merge.sh /usr/local/bin/maint-login-merge
			install -m 0755 /opt/maintenance-scripts/maint-shell.sh /usr/local/bin/maint-shell
			install -m 0755 /opt/maintenance-scripts/maint-cache-reset.sh /usr/local/bin/maint-cache-reset
			install -m 0755 /opt/maintenance-scripts/maint-graphql-cache-reset.sh /usr/local/bin/maint-graphql-cache-reset
			install -m 0755 /opt/maintenance-scripts/maint-db-import.sh /usr/local/bin/maint-db-import
			install -m 0755 /opt/maintenance-scripts/maint-list-db-backups.sh /usr/local/bin/maint-list-db-backups
			install -m 0755 /opt/maintenance-scripts/maint-help /usr/local/bin/maint-help
			
			\(#config.maintenance.shell.entrypointAdditionalCommands)
			
			touch /tmp/entrypoint_done
			
			# Start an interactive login shell for the maintainer with merged env
			# kubectl attach -it deployment/pimcore-maintenance-shell
			exec /usr/local/bin/maint-login-merge "$maintainer_user_name" /var/www/pimcore
			"""

		"maint-cache-reset.sh": """
			#!/usr/bin/env bash
			# Reset Pimcore cache: retries cache:clear until it succeeds, then warms cache
			set -euo pipefail
			
			target_user="${CACHE_RESET_USER:-www-data}"
			memory_limit="${CACHE_RESET_MEMORY_LIMIT:-2G}"
			console_bin="${PIMCORE_CONSOLE_BIN:-bin/console}"
			php_bin="${PHP_BIN:-php}"
			retry_delay="${CACHE_RESET_RETRY_DELAY:-1}"
			
			cd "/var/www/pimcore" || {
				echo "Failed to change directory to /var/www/pimcore" >&2
				exit 1
			}
			
			clear_cmd=(sudo -E -u "$target_user" "$php_bin" -d "memory_limit=${memory_limit}" "$console_bin" cache:clear --no-warmup)
			warmup_cmd=(sudo -E -u "$target_user" "$php_bin" -d "memory_limit=${memory_limit}" "$console_bin" cache:warmup)
			
			while true; do
				if "${clear_cmd[@]}"; then
					break
				fi
				echo "cache:clear failed; retrying in ${retry_delay}s..." >&2
				sleep "$retry_delay"
			done
			
			"${warmup_cmd[@]}"
			"""

		"maint-graphql-cache-reset.sh": """
			#!/usr/bin/env bash
			# Reset datahub GraphQL cache
			set -euo pipefail
			
			target_user="${CACHE_RESET_USER:-www-data}"
			console_bin="${PIMCORE_CONSOLE_BIN:-bin/console}"
			php_bin="${PHP_BIN:-php}"
			
			cd "/var/www/pimcore" || {
				echo "Failed to change directory to /var/www/pimcore" >&2
				exit 1
			}
			
			sudo -E -u "$target_user" "$php_bin" "$console_bin" cache:pool:invalidate-tags datahub
			"""

		"maint-shell.sh": """
			#!/usr/bin/env bash
			# Convenient wrapper to open a maintainer login shell with merged env,
			# or run a command non-interactively as the maintainer user.
			#   Interactive:     maint-shell
			#   Non-interactive: maint-shell git status
			set -euo pipefail
			: "${MAINTAINER_USER_NAME:=\(#config.maintenance.shell.maintainer.userName)}"
			: "${MAINTAINER_CWD:=/var/www/pimcore}"
			
			exec /usr/local/bin/maint-login-merge "$MAINTAINER_USER_NAME" "$MAINTAINER_CWD" "$@"
			"""

		"maint-login-merge.sh": """
			#!/usr/bin/env bash
			# Usage: maint-login-merge <user> <cd_target> [cmd [args...]]
			#   Interactive:     maint-login-merge maintainer /var/www/pimcore
			#   Non-interactive: maint-login-merge maintainer /var/www/pimcore git status
			set -euo pipefail
			
			if [[ $# -lt 1 ]]; then
				echo "Usage: $0 <user> <cd_target> [cmd [args...]]" >&2
				exit 2
			fi
			
			user="$1"
			cd_target="${2:-}"
			shift; shift 2>/dev/null || shift $# # consume user + cd_target
			# Remaining args ($@) are the command to run (empty = interactive shell)
			
			# Get the *names* of variables in the maintainer's true login env
			login_names="$(
				env -i su -l "$user" -s /bin/sh -c 'env | cut -d= -f1 | LC_ALL=C sort -u'
			)"
			
			# Names in current (container) env
			container_names="$(env | cut -d= -f1 | LC_ALL=C sort -u)"
			
			# Compute container-only env names (login takes precedence on collisions)
			# Drop noisy session vars; remove the grep if you want literally everything.
			extras_names_raw="$(
				comm -13 \\
					<(printf '%s\\n' "$login_names") \\
					<(printf '%s\\n' "$container_names") |
					grep -Ev '^(PWD|OLDPWD|SHLVL|_)$' || true
			)"
			
			extras_names_combined="$extras_names_raw"
			if [[ -n "${cd_target}" ]]; then
				export MAINTAINER_CWD="$cd_target"
				extras_names_combined="$(printf '%s\\n%s\\n' "$extras_names_combined" "MAINTAINER_CWD")"
			fi
			
			extras_clean="$(printf '%s\\n' "$extras_names_combined" | grep -Ev '^\\s*$' || true)"
			
			if [[ -n "$extras_clean" ]]; then
				extras_csv="$(printf '%s\\n' "$extras_clean" | LC_ALL=C sort -u | paste -sd, -)"
			else
				extras_csv=""
			fi
			
			su_args=(-l "$user" --shell /bin/bash)
			if [[ -n "${extras_csv}" ]]; then
				su_args+=(--whitelist-environment="$extras_csv")
			fi
			
			if [[ $# -gt 0 ]]; then
				# Non-interactive: run the given command as the user.
				# Build a properly escaped command string for su -c.
				# The login shell sources .profile (which cd's to MAINTAINER_CWD),
				# but we cd explicitly as well for safety.
				cmd_str=""
				if [[ -n "$cd_target" ]]; then
					cmd_str="cd $(printf '%q' "$cd_target") && "
				fi
				cmd_str+="exec"
				for arg in "$@"; do
					cmd_str+=" $(printf '%q' "$arg")"
				done
				exec su "${su_args[@]}" -c "$cmd_str"
			else
				exec su "${su_args[@]}"
			fi
			"""

		"maint-list-db-backups.sh": """
			#!/usr/bin/env bash
			# List Pimcore MySQL backups from /backup, newest first. Supports --latest to print only the newest entry.
			set -euo pipefail
			
			backup_dir="${BACKUP_DIR:-/backup}"
			latest_only=false
			
			show_usage() {
				printf '%s\\n' \\
					"Usage: maint-list-db-backups [--latest] [--help]" \\
					"" \\
					"List MySQL backups stored in \\$BACKUP_DIR (default: /backup), newest first." \\
					"--latest prints only the newest backup path."
			}
			
			while [[ $# -gt 0 ]]; do
				case "$1" in
				--latest | -l)
					latest_only=true
					shift
					;;
				-h | --help)
					show_usage
					exit 0
					;;
				*)
					echo "Error: unexpected argument '$1'." >&2
					show_usage
					exit 2
					;;
				esac
			done
			
			if [[ ! -d "$backup_dir" ]]; then
				echo "Error: backup directory '$backup_dir' not found." >&2
				exit 1
			fi
			
			mapfile -t backup_lines < <(
				find "$backup_dir" -maxdepth 1 -type f \\( -name '*.sql' -o -name '*.sql.*' \\) -printf '%T@\\t%p\\n' \\
					| sort -nr
			)
			
			if [[ ${#backup_lines[@]} -eq 0 ]]; then
				echo "No database backups found in $backup_dir." >&2
				exit 3
			fi
			
			if [[ "$latest_only" == "true" ]]; then
				latest_path="${backup_lines[0]#*$'\\t'}"
				echo "$latest_path"
				exit 0
			fi
			
			for line in "${backup_lines[@]}"; do
				path="${line#*$'\\t'}"
				echo "$path"
			done
			"""

		"maint-help": """
			#!/usr/bin/env bash
			# Show help for maintenance shell usage
			set -euo pipefail
			
			cat <<'EOF'
			Pimcore Maintenance Shell Help
			
			This container provides a maintenance shell environment for Pimcore.
			
			Available commands:
			
			- maint-shell
			  Opens an interactive login shell as the maintainer user with merged environment variables.
			
			- maint-cache-reset
			  Resets the Pimcore cache by repeatedly attempting to clear it until successful, then warms the cache.
			
			- maint-graphql-cache-reset
			  Resets the Datahub GraphQL cache.
			
			- maint-db-import
			  Imports a SQL dump into the Pimcore database; accepts --dump-file or reads from STDIN and handles common compression formats.
			
			- maint-list-db-backups
			  Lists MySQL backups from /backup, newest first. Use --latest to print only the newest backup path.
			
			Usage Examples:
			
			To open a maintenance shell:
			  kubectl exec -it deployment/pimcore-maintenance-shell -- maint-shell
			
			To reset Pimcore cache:
			  kubectl exec -it deployment/pimcore-maintenance-shell -- maint-cache-reset
			
			To reset Datahub GraphQL cache:
			  kubectl exec -it deployment/pimcore-maintenance-shell -- maint-graphql-cache-reset
			
			To import a database dump (and clear the cache afterward):
			  kubectl exec -i deployment/pimcore-maintenance-shell -- maint-db-import --help
			  kubectl exec -i deployment/pimcore-maintenance-shell -- maint-db-import --dump-file /tmp/dump.sql.gz
			  cat /tmp/dump.sql.xz | kubectl exec -i deployment/pimcore-maintenance-shell -- maint-db-import
			
			To inspect database backups:
			  kubectl exec deployment/pimcore-maintenance-shell -- maint-list-db-backups --latest
			
			Note: -it flags are recommended for interactive commands and colored output.
			
			EOF
			"""

		"maint-db-import.sh": """
			#!/usr/bin/env bash
			# Import a SQL dump into the Pimcore database, supporting common compression formats.
			set -euo pipefail
			
			show_usage() {
				printf '%s\\n' \\
					"Usage: maint-db-import [--dump-file <path>|-f <path>] [--help]" \\
					"" \\
					"Import a Pimcore database dump from a file in the container or STDIN. Supported compressions:" \\
					"plain text, gzip (.gz), bzip2 (.bz2), xz (.xz), and zstd (.zst/.zstd)." \\
					"Clears and warms the Pimcore cache after import." \\
					"" \\
					"Examples:" \\
					"  maint-db-import --dump-file /tmp/dump.sql.gz" \\
					"  zcat /tmp/dump.sql.gz | maint-db-import" \\
					"  kubectl exec -i deployment/pimcore-maintenance-shell -- maint-db-import --dump-file /tmp/dump.sql"
			}
			
			dump_file=""
			force=false
			
			while [[ $# -gt 0 ]]; do
				case "$1" in
				--dump-file | -f)
					if [[ $# -lt 2 ]]; then
						echo "Error: $1 requires a path argument." >&2
						show_usage
						exit 2
					fi
					dump_file="$2"
					shift 2
					;;
				--force)
			        force=true
			        shift
			        ;;
				-h | --help)
					show_usage
					exit 0
					;;
				--)
					shift
					break
					;;
				*)
					if [[ -z "$dump_file" ]]; then
						dump_file="$1"
						shift
					else
						echo "Error: unexpected argument '$1'." >&2
						show_usage
						exit 2
					fi
					;;
				esac
			done
			
			if [[ -z "$dump_file" ]]; then
				if [[ -t 0 ]]; then
					echo "Error: no dump provided via --dump-file and STDIN is not piped." >&2
					show_usage
					exit 2
				fi
				dump_file="-"
			fi
			
			# if APP_ENV is not "dev" and --force is not given, refuse to run
			app_env="${APP_ENV:-prod}"
			if [[ "$app_env" != "dev" && "$force" != "true" ]]; then
			    echo "Error: APP_ENV is '$app_env'. To run this script, set APP_ENV=dev or use --force." >&2
			    exit 5
			fi
			
			cleanup_path=""
			if [[ "$dump_file" == "-" ]]; then
				tmp_file="$(mktemp -t pimcore-db-import.XXXXXX)"
				cleanup_path="$tmp_file"
				trap '[[ -n "$cleanup_path" ]] && rm -f "$cleanup_path"' EXIT
				cat >"$tmp_file"
				source_path="$tmp_file"
			else
				source_path="$dump_file"
				if [[ ! -f "$source_path" ]]; then
					echo "Error: dump file '$source_path' not found." >&2
					exit 2
				fi
			fi
			
			detect_compression() {
				local path="$1"
				if command -v file >/dev/null 2>&1; then
					local mime
					mime="$(file -b --mime-type "$path" 2>/dev/null || true)"
					case "$mime" in
					application/gzip)
						echo "gzip"
						return
						;;
					application/x-bzip2)
						echo "bzip2"
						return
						;;
					application/x-xz)
						echo "xz"
						return
						;;
					application/zstd)
						echo "zstd"
						return
						;;
					esac
				fi
				case "$path" in
				*.gz | *.sql.gz | *.tgz) echo "gzip" ;;
				*.bz2 | *.sql.bz2 | *.tbz2) echo "bzip2" ;;
				*.xz | *.sql.xz) echo "xz" ;;
				*.zst | *.sql.zst | *.zstd) echo "zstd" ;;
				*) echo "plain" ;;
				esac
			}
			
			compression="$(detect_compression "$source_path")"
			reader_cmd=(cat "$source_path")
			
			require_cmd() {
				if ! command -v "$1" >/dev/null 2>&1; then
					echo "Error: required command '$1' is not available in PATH." >&2
					exit 4
				fi
			}
			
			case "$compression" in
			plain)
				reader_cmd=(cat "$source_path")
				;;
			gzip)
				require_cmd gzip
				reader_cmd=(gzip -cd -- "$source_path")
				;;
			bzip2)
				require_cmd bzip2
				reader_cmd=(bzip2 -cd -- "$source_path")
				;;
			xz)
				require_cmd xz
				reader_cmd=(xz -cd -- "$source_path")
				;;
			zstd)
				require_cmd zstd
				reader_cmd=(zstd -cd -- "$source_path")
				;;
			*)
				echo "Error: unsupported compression type '$compression'." >&2
				exit 3
				;;
			esac
			
			require_cmd yq
			require_cmd mysql
			
			config_path="${DATABASE_CONFIG_PATH:-/var/www/pimcore/config/local/database.yaml}"
			if [[ ! -f "$config_path" ]]; then
				echo "Error: database config '$config_path' not found." >&2
				exit 2
			fi
			
			yaml_query_base='.doctrine.dbal.connections.default'
			mysql_host="$(yq -r "${yaml_query_base}.host // empty" "$config_path")"
			mysql_port="$(yq -r "${yaml_query_base}.port // empty" "$config_path")"
			mysql_user="$(yq -r "${yaml_query_base}.user // empty" "$config_path")"
			mysql_password="$(yq -r "${yaml_query_base}.password // empty" "$config_path")"
			mysql_dbname="$(yq -r "${yaml_query_base}.dbname // empty" "$config_path")"
			
			if [[ -z "$mysql_host" || -z "$mysql_user" || -z "$mysql_password" || -z "$mysql_dbname" ]]; then
				echo "Error: one or more required database settings (host/user/password/dbname) are missing in $config_path." >&2
				exit 1
			fi
			
			if [[ -z "$mysql_port" || "$mysql_port" == "null" ]]; then
				mysql_port="3306"
			fi
			
			mysql_cmd=(
				mysql
				--protocol=tcp
				--host="$mysql_host"
				--port="$mysql_port"
				--user="$mysql_user"
				"$mysql_dbname"
			)
			
			echo "Importing dump into database '$mysql_dbname' at ${mysql_host}:${mysql_port}..." >&2
			if ! "${reader_cmd[@]}" | MYSQL_PWD="$mysql_password" "${mysql_cmd[@]}"; then
				echo "Error: database import failed." >&2
				exit 1
			fi
			echo "Database import completed successfully." >&2
			echo "Resetting Pimcore cache..." >&2
			/usr/local/bin/maint-cache-reset
			echo "Pimcore cache reset completed." >&2
			"""
	}
}

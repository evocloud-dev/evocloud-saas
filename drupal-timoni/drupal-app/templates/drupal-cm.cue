package templates

import (
	"strings"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#DrupalConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#ConfigMapKind
	#Meta:   #config.metadata
	#Data: {
		"php.ini":                 #config.drupal.conf.php_ini + "\n" + strings.Join([ for k, v in #config.drupal.php.ini { "\(k) = \(v)" }], "\n")
		"opcache-recommended.ini": #config.drupal.conf.opcache
		"www.conf":                #config.drupal.conf.www_conf + "\n" + #config.drupal.php.fpm
		
		"settings.php": {
			if #config.drupal.version == "d9" { #config.drupal.conf.settings_d9 }
			if #config.drupal.version == "d10" { #config.drupal.conf.settings_d10 }
			if #config.drupal.version == "d11" { #config.drupal.conf.settings_d11 }
			if !strings.HasPrefix(#config.drupal.version, "d") { #config.drupal.conf.settings_php }
		}

		"services.yml":            #config.drupal.services
		if #config.drupal.extraSettings != "" {
			"extra.settings.php": "<?php\n\n" + #config.drupal.extraSettings
		}
	}
}

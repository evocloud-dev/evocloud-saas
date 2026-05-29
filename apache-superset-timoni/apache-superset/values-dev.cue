package main

values: {
	bootstrapScript: #"""
		#!/bin/bash
		apt update && apt install -y gcc libpq-dev python3-dev pkg-config libmariadb-dev libsasl2-dev
		# Ensure we install into Superset's virtual environment
		export VIRTUAL_ENV=/app/.venv
		export PATH="$VIRTUAL_ENV/bin:$PATH"
		uv pip install psycopg2-binary \
			pydynamodb clickhouse-connect \
			pydruid pyhive impyla kylinpy pinotdb sqlalchemy-solr sqlalchemy-redshift pydoris \
			sqlalchemy-drill pymssql couchbase-sqlalchemy sqlalchemy-cratedb denodo-sqlalchemy \
			pyathena[pandas] PyAthenaJDBC  sqlalchemy_dremio elasticsearch-dbapi sqlalchemy-exasol \
			sqlalchemy-bigquery shillelagh[gsheetsapi] firebolt-sqlalchemy ibm_db_sa nzalchemy mysqlclient oceanbase_py \
			cx_Oracle sqlalchemy-parseable hdbcli sqlalchemy-hana sqlalchemy-singlestoredb starrocks snowflake-sqlalchemy \
			taospy taos-ws-py teradatasqlalchemy trino sqlalchemy-vertica-python ydb-sqlalchemy
			cockroachdb && \
		if [ ! -f ~/bootstrap ]; then echo "Running Superset with uid 0" > ~/bootstrap; fi 
		"""#
}
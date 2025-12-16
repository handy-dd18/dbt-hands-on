FROM python:3.11-slim

WORKDIR /dbt

RUN pip install --no-cache-dir dbt-core dbt-postgres

ENTRYPOINT ["/bin/bash"]

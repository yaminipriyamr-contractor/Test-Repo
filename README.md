# Test-Repo

Dummy dbt project for local model testing. Uses DuckDB so Snowflake is not required.

## Setup

```bash
cd C:\Procore\Test-Repo
python -m pip install dbt-core dbt-duckdb
dbt deps --profiles-dir .
```

## Run

```bash
dbt debug --profiles-dir .
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

## Add a dummy model

1. Put SQL in `models/staging/` or `models/marts/`.
2. Optional CSV dummy data goes in `seeds/`.
3. Reference it with `{{ ref('your_seed_or_model') }}`.
4. Run `dbt run --select your_model --profiles-dir .`

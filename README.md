# Literacy Report Service (Rails)

Rails full-stack app for the literacy assessment and reporting platform.

## Requirements
- Ruby 3.4+
- Rails 8.1+

## Local setup (SQLite)
```bash
bundle install
bin/rails db:prepare
bin/dev
```

## Production (Supabase / PostgreSQL)
Set `DATABASE_URL` and `RAILS_MASTER_KEY` in Railway, then deploy.
See `.env.example` for the required variables.

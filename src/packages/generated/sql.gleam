// THIS FILE IS GENERATED. DO NOT EDIT. 
// Regenerate with `gleam run -m codegen`

import gleam/pgo
import gleam/result
import gleam/dynamic
import packages/error.{Error}

pub type QueryResult(t) =
  Result(pgo.Returned(t), Error)

pub fn upsert_most_recent_hex_timestamp(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into most_recent_hex_timestamp
  (id, timestamp)
values
  (true, to_timestamp($1))
on conflict (id) do update
set
  timestamp = to_timestamp($1);
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_hex_user(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "-- Insert or update a hex_user record.
-- If the username is already in use, update the email and hex_url.
insert into hex_user
  (username, email, hex_url)
values
  ($1, $2, $3)
on conflict (username) do update
set
  email = $2
, hex_url = $3
returning
  id
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_most_recent_hex_timestamp(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  floor(extract('epoch' from timestamp))::bigint as timestamp
from most_recent_hex_timestamp
limit 1
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn migrate_schema(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "do $$
begin

create table if not exists most_recent_hex_timestamp (
  id boolean primary key default true,
  timestamp timestamp without time zone not null
  -- we use a constraint to enforce that the id is always the value `true` so
  -- now this table can only hold one row.
  constraint most_recent_hex_timestamp_singleton check (id)
);

create table if not exists packages
( id serial primary key
, name text not null unique
, hex_html_url text
, docs_html_url text
, inserted_in_hex_at timestamp with time zone
, updated_in_hex_at timestamp with time zone
, links jsonb not null default '{}'
, licenses text array not null default '{}'
, description text
);

create table if not exists hex_user
( id serial primary key
, username text not null unique
, email text
, hex_url text
);

create table if not exists package_ownership
( package_id integer references packages(id) on delete cascade
, hex_user_id integer references hex_user(id) on delete cascade
, primary key (package_id, hex_user_id)
);

if to_regtype('retirement_reason') is null then
  create type retirement_reason as enum
  ( 'other'
  , 'invalid'
  , 'security'
  , 'deprecated'
  , 'renamed'
  );
end if;

create table if not exists releases
( id serial primary key
, package_id integer references packages(id) on delete cascade
, version text not null
, hex_url text not null
, retirement_reason retirement_reason
, retirement_message text
);

end
$$;
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}
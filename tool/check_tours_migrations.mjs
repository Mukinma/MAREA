// Applies the complete migration chain in isolated PostgreSQL/WASM, then executes
// the real read-only release contract against catalog grants/policies/functions.
import {readFile,readdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite}=await import(process.env.MAREA_PGLITE_MODULE||'@electric-sql/pglite');
const db=new PGlite();
try{
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;
 create schema auth;create schema storage;create schema supabase_migrations;
 grant usage on schema public,auth,storage to anon,authenticated,service_role;
 create table auth.users(id uuid primary key,raw_user_meta_data jsonb not null default '{}');
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
 alter table storage.objects enable row level security;grant select,insert,update,delete on storage.objects to authenticated;
 create function storage.foldername(name text) returns text[] language sql immutable as $$select string_to_array(name,'/')$$;
 create table supabase_migrations.schema_migrations(version text primary key);
 create publication supabase_realtime;`);
 const root=new URL('../supabase/migrations/',import.meta.url);
 const files=(await readdir(root)).filter(f=>/^\d+.*\.sql$/.test(f)).sort();
 for(const file of files){await db.exec(await readFile(new URL(file,root),'utf8'));await db.query('insert into supabase_migrations.schema_migrations values($1)',[file.split('_')[0]]);}
 const contract=(await db.query(await readFile(new URL('./backend_contract.sql',import.meta.url),'utf8'))).rows[0];
 for(const [flag,value] of Object.entries(contract))assert.equal(value,true,flag);
 console.log(`${files.length} migrations applied; ${Object.keys(contract).length} real catalog contract flags passed.`);
}finally{await db.close();}

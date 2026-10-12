import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const {PGlite}=await import(process.env.MAREA_PGLITE_MODULE || '@electric-sql/pglite');
const db=new PGlite();
try {
 await db.exec(`create role anon;create role authenticated;create role service_role;
 create table public.posts(id uuid primary key,location_latitude double precision,location_longitude double precision);
 create table public.missions(like public.posts including all);create table public.mission_drafts(id uuid primary key,data jsonb);
 create function public.create_mission(mission_input jsonb) returns uuid language sql as $$select null::uuid$$;
 create function public.update_mission(mission_id uuid,mission_input jsonb) returns void language sql as $$select$$;
 create function public.save_mission_draft(draft_id uuid,draft_input jsonb) returns uuid language sql as $$select draft_id$$;`);
 await db.exec(readFileSync('supabase/migrations/021_content_cities.sql','utf8'));
 const id='00000000-0000-0000-0000-000000000099';
 const old={name:'Puebla',point:{latitude:19.1,longitude:-98.1}},fresh={name:'Puebla',point:{latitude:19.2,longitude:-98.2}};
 await db.query('insert into public.posts(id,location_latitude,location_longitude,location_city) values($1,19.1,-98.1,$2)',[id,old]);
 await db.query('update public.posts set location_latitude=19.2,location_longitude=-98.2,location_city=$1 where id=$2',[fresh,id]);
 assert.deepEqual((await db.query('select location_city from public.posts')).rows[0].location_city,fresh,'fresh same-city metadata must persist when its exact point changes');
 await db.query('update public.posts set location_latitude=19.3,location_longitude=-98.3,location_city=$1 where id=$2',[{name:'Other city',point:{latitude:19.2,longitude:-98.2}},id]);
 assert.equal((await db.query('select location_city from public.posts')).rows[0].location_city,null,'different metadata carrying an old point must be invalidated');
 await db.query('update public.posts set location_city=$1 where id=$2',[{name:'Puebla',point:{latitude:19.3,longitude:-98.3}},id]);
 await db.query('update public.posts set location_latitude=19.4 where id=$1',[id]);
 assert.equal((await db.query('select location_city from public.posts')).rows[0].location_city,null,'implicit carry of prior city must be invalidated');
 await db.query('update public.posts set location_city=$1 where id=$2',[{name:'Puebla',point:{latitude:19.4,longitude:-98.3}},id]);
 await db.query('update public.posts set location_latitude=null,location_longitude=null where id=$1',[id]);
 assert.equal((await db.query('select location_city from public.posts')).rows[0].location_city,null,'coordinate removal must clear city metadata');
 console.log('City provenance SQL: fresh same-city point preserved; stale explicit/implicit city and coordinate removal invalidated');
} finally {await db.close();}

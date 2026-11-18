import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { PGlite } from "npm:@electric-sql/pglite@0.3.14";

const user = "00000000-0000-4000-8000-000000000001";
const actor = "00000000-0000-4000-8000-000000000002";
const device = "00000000-0000-4000-8000-000000000003";
const post = "00000000-0000-4000-8000-000000000004";
const session = "00000000-0000-4000-8000-000000000005";
const otherSession = "00000000-0000-4000-8000-000000000006";
const fixture = `
create role anon; create role authenticated; create role service_role;
create schema auth;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create function auth.jwt() returns jsonb language sql as $$select nullif(current_setting('request.jwt.claims',true),'')::jsonb$$;
create table auth.sessions(id uuid primary key,user_id uuid not null,aal text,not_after timestamptz);
create table auth.mfa_factors(user_id uuid not null,status text not null);
create table public.profiles(id uuid primary key,full_name text);
create table public.posts(id uuid primary key);
create table public.missions(id uuid primary key);
create table public.account_deletion_requests(user_id uuid);
create function public.community_active_account() returns uuid language plpgsql as $$begin
 if auth.uid() is null then raise exception 'authentication_required'; end if; return auth.uid(); end;$$;
create table public.notifications(id uuid primary key default gen_random_uuid(),recipient_id uuid references public.profiles(id),actor_id uuid not null references public.profiles(id),
 post_id uuid references public.posts(id),mission_id uuid references public.missions(id),kind text,source_id uuid,event_key text unique,post_title text,
 created_at timestamptz not null default clock_timestamp(),read_at timestamptz,
 constraint notifications_kind_check check(kind in ('reaction','comment')),
 constraint notifications_one_target check(num_nonnulls(post_id,mission_id)=1),check(recipient_id<>actor_id));
insert into public.profiles values('${user}','Receptor'),('${actor}','Creador');
insert into public.posts values('${post}');
insert into auth.sessions(id,user_id,aal) values('${session}','${user}','aal1'),('${otherSession}','${actor}','aal1');
select set_config('request.jwt.claim.sub','${user}',false);
select set_config('request.jwt.claims','{"session_id":"${session}"}',false);`;

async function migrateCategories(db: PGlite) {
  await db.exec(
    await Deno.readTextFile(
      new URL(
        "../../migrations/20261118000002_notification_categories.sql",
        import.meta.url,
      ),
    ),
  );
}

async function database({ legacy = false } = {}) {
  const db = new PGlite();
  await db.exec(fixture);
  await db.exec(
    await Deno.readTextFile(
      new URL("../../migrations/014_android_push.sql", import.meta.url),
    ),
  );
  if (!legacy) await migrateCategories(db);
  return db;
}
async function scalar(db: PGlite, sql: string) {
  const result = await db.query<{ value: unknown }>(sql);
  return result.rows[0]?.value;
}
async function ready(db: PGlite) {
  await db.exec(
    `select public.record_notification_activity('America/Mexico_City');
    select public.register_notification_device('${device}','abcdefghijklmnopqrstuvwxyz123456789',true);
    update private.push_settings set enabled=true;`,
  );
}

Deno.test("database enqueues one job per event/device and isolates private data", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','comment','comment:1','Pieza');`,
    );
    assertEquals(
      await scalar(db, "select count(*)::int as value from private.push_queue"),
      1,
    );
    await db.exec("update public.notifications set read_at=clock_timestamp()");
    assertEquals(
      await scalar(db, "select count(*)::int as value from private.push_queue"),
      1,
    );
    assertEquals(
      await scalar(
        db,
        "select has_table_privilege('authenticated','private.push_queue','select') as value",
      ),
      false,
    );
    assertEquals(
      await scalar(
        db,
        "select has_function_privilege('authenticated','public.claim_push_jobs(integer)','execute') as value",
      ),
      false,
    );
    assertEquals(
      await scalar(
        db,
        "select has_table_privilege('authenticated','public.notification_devices','select') as value",
      ),
      false,
    );
    assertEquals(
      await scalar(
        db,
        "select jsonb_array_length(public.claim_push_jobs())::int as value",
      ),
      0,
    );
  } finally {
    await db.close();
  }
});
Deno.test("leased jobs cannot be claimed twice and revoked devices stop delivery", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','reaction','reaction:1','Pieza');`,
    );
    const jobs = await scalar(
      db,
      "select public.claim_push_jobs() as value",
    ) as { queue_id: string; lease_id: string }[];
    assertEquals(jobs.length, 1);
    assertEquals(
      await scalar(
        db,
        "select jsonb_array_length(public.claim_push_jobs())::int as value",
      ),
      0,
    );
    assertEquals(
      await scalar(
        db,
        `select public.push_job_is_current('${jobs[0].queue_id}','${
          jobs[0].lease_id
        }') as value`,
      ),
      true,
    );
    await db.exec(`select public.unregister_notification_device('${device}')`);
    assertEquals(
      await scalar(
        db,
        `select public.push_job_is_current('${jobs[0].queue_id}','${
          jobs[0].lease_id
        }') as value`,
      ),
      false,
    );
  } finally {
    await db.close();
  }
});
Deno.test("reminders respect inactivity, daytime, weekly budget and cancellation", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `update public.notification_preferences set last_seen_at='2026-10-01T17:00:00Z';
      select private.schedule_marea_messages('2026-10-05T17:00:00Z');`,
    );
    assertEquals(
      await scalar(
        db,
        `select (next_marea_at>'2026-10-05T17:00:00Z' and
      extract(hour from next_marea_at at time zone timezone)>=10 and
      extract(hour from next_marea_at at time zone timezone)<19) as value from public.notification_preferences`,
      ),
      true,
    );
    await db.exec(
      `update public.notification_preferences set next_marea_at='2026-10-05T17:00:00Z';
      select private.schedule_marea_messages('2026-10-05T17:00:00Z');`,
    );
    assertEquals(
      await scalar(
        db,
        "select count(*)::int as value from public.notifications where kind='marea_message'",
      ),
      1,
    );
    await db.exec(
      `update public.notification_preferences set next_marea_at='2026-10-06T17:00:00Z';
      select private.schedule_marea_messages('2026-10-06T17:00:00Z');`,
    );
    assertEquals(
      await scalar(
        db,
        "select count(*)::int as value from public.notifications where kind='marea_message'",
      ),
      1,
    );
    await db.exec(
      `update public.notification_preferences set next_marea_at='2026-10-08T17:00:00Z';
      select private.schedule_marea_messages('2026-10-08T17:00:00Z');
      update public.notification_preferences set next_marea_at='2026-10-11T17:00:00Z';
      select private.schedule_marea_messages('2026-10-11T17:00:00Z');`,
    );
    assertEquals(
      await scalar(
        db,
        "select count(*)::int as value from public.notifications where kind='marea_message'",
      ),
      2,
    );
    await db.exec(
      `select public.record_notification_activity('America/Mexico_City')`,
    );
    assertEquals(
      await scalar(
        db,
        "select count(*)::int as value from private.push_queue where status in ('pending','processing')",
      ),
      0,
    );
    assertEquals(
      await scalar(
        db,
        "select next_marea_at as value from public.notification_preferences",
      ),
      null,
    );
  } finally {
    await db.close();
  }
});
Deno.test("unknown timezones and another account changing a device are rejected", async () => {
  const db = await database();
  try {
    await ready(db);
    await assertRejects(() =>
      db.exec("select public.record_notification_activity('not/a/zone')")
    );
    await db.exec(
      `select set_config('request.jwt.claim.sub','${actor}',false);
      select set_config('request.jwt.claims','{"session_id":"${otherSession}"}',false)`,
    );
    await assertRejects(() =>
      db.exec(
        `select public.register_notification_device('${device}','another-invalid-owner-token-12345',true)`,
      )
    );
  } finally {
    await db.close();
  }
});

Deno.test("late invalid-token results cannot disable a renewed token", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','reaction','reaction:rotation','Pieza');`,
    );
    const jobs = await scalar(
      db,
      "select public.claim_push_jobs() as value",
    ) as { queue_id: string; lease_id: string }[];
    await db.exec(
      `select public.register_notification_device('${device}','renewed-valid-token-123456789',true);
      select public.finish_push_job('${jobs[0].queue_id}','${
        jobs[0].lease_id
      }','invalid_token');`,
    );
    assertEquals(
      await scalar(
        db,
        "select enabled as value from public.notification_devices",
      ),
      true,
    );
    assertEquals(
      await scalar(db, "select status as value from private.push_queue"),
      "pending",
    );
  } finally {
    await db.close();
  }
});
Deno.test("the last expired lease becomes a terminal failure", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','reaction','reaction:expiry','Pieza');
      update private.push_queue set status='processing',attempts=5,lease_until=clock_timestamp()-interval '1 minute';
      select public.claim_push_jobs();`,
    );
    assertEquals(
      await scalar(db, "select status as value from private.push_queue"),
      "failed",
    );
  } finally {
    await db.close();
  }
});

Deno.test("migration preserves legacy preferences and queued delivery until the device rebinds", async () => {
  const db = await database({ legacy: true });
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','comment','comment:legacy','Pieza');`,
    );
    const previous = await scalar(db, "select public.claim_push_jobs() as value") as {
      queue_id: string;
      lease_id: string;
    }[];
    assertEquals(previous.length, 1);
    await migrateCategories(db);
    assertEquals(
      await scalar(db, `select public.push_job_is_current('${previous[0].queue_id}','${previous[0].lease_id}') as value`),
      true,
    );
    await db.exec("select public.set_notification_preferences(false,true)");
    assertEquals(
      await scalar(
        db,
        "select array[chat_enabled,missions_enabled,collaborations_enabled,reactions_enabled,comments_enabled,marea_enabled] as value from public.notification_preferences",
      ),
      [true, false, false, false, false, true],
    );
    assertEquals(
      await scalar(
        db,
        "select enabled as value from public.notification_devices",
      ),
      true,
    );
    await ready(db);
    assertEquals(
      await scalar(
        db,
        "select session_id as value from public.notification_devices",
      ),
      session,
    );
  } finally {
    await db.close();
  }
});

Deno.test("revoking a session suspends only the affected account's unbound installations", async () => {
  const db = await database({ legacy: true });
  try {
    await ready(db);
    await migrateCategories(db);
    await db.exec(`delete from auth.sessions where id='${otherSession}';`);
    assertEquals(await scalar(db, "select enabled as value from public.notification_devices"), true);
    await db.exec(`delete from auth.sessions where id='${session}';`);
    assertEquals(await scalar(db, "select enabled as value from public.notification_devices"), false);
    await assertRejects(() =>
      db.exec(`select public.register_notification_device('${device}','valid-length-token-1234',true)`)
    );
  } finally {
    await db.close();
  }
});

Deno.test("a granular mute cancels a claimed alert and preserves the inbox", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','reaction','reaction:mute','Pieza'),
            ('${user}','${actor}','${post}','comment','comment:keep','Pieza');`,
    );
    const jobs = await scalar(
      db,
      "select public.claim_push_jobs() as value",
    ) as {
      queue_id: string;
      lease_id: string;
      category: string;
    }[];
    const reaction = jobs.find((job) => job.category === "reactions")!;
    const comment = jobs.find((job) => job.category === "comments")!;
    await db.exec("select public.set_notification_category('reactions',false)");
    await db.exec(
      "select public.set_notification_category('collaborations',false)",
    );
    assertEquals(
      await scalar(
        db,
        `select public.push_job_is_current('${reaction.queue_id}','${reaction.lease_id}') as value`,
      ),
      false,
    );
    assertEquals(
      await scalar(
        db,
        `select public.push_job_is_current('${comment.queue_id}','${comment.lease_id}') as value`,
      ),
      true,
    );
    assertEquals(
      await scalar(
        db,
        "select array[reactions_enabled,collaborations_enabled,comments_enabled] as value from public.notification_preferences",
      ),
      [false, false, true],
    );
    assertEquals(
      await scalar(
        db,
        "select count(*)::int as value from public.notifications",
      ),
      2,
    );
  } finally {
    await db.close();
  }
});

Deno.test("legacy chat can reach active users with reminders disabled", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `select public.set_notification_category('reminders',false);
      insert into public.notifications(recipient_id,kind,event_key,post_title)
      values('${user}','marea_message','chat_message:1','Nuevo mensaje'),
            ('${user}','marea_message','marea:test','Un recordatorio');
      select public.record_notification_activity('America/Mexico_City');`,
    );
    const jobs = await scalar(
      db,
      "select public.claim_push_jobs() as value",
    ) as {
      queue_id: string;
      lease_id: string;
      category: string;
      ttl_seconds: number;
    }[];
    assertEquals(
      jobs.map(({ category, ttl_seconds }) => [category, ttl_seconds]),
      [["chat", 86400]],
    );
    assertEquals(
      await scalar(
        db,
        `select public.push_job_is_current('${jobs[0].queue_id}','${
          jobs[0].lease_id
        }') as value`,
      ),
      true,
    );
  } finally {
    await db.close();
  }
});

Deno.test("a recent chat does not consume the reminder schedule budget", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `update public.notification_preferences set last_seen_at='2026-10-01T17:00:00Z',
          next_marea_at='2026-10-05T17:00:00Z';
      insert into public.notifications(recipient_id,kind,event_key,post_title,created_at)
      values('${user}','marea_message','chat_request:1','Solicitud','2026-10-05T16:00:00Z');
      select private.schedule_marea_messages('2026-10-05T17:00:00Z');`,
    );
    assertEquals(
      await scalar(
        db,
        "select count(*)::int as value from public.notifications where event_key like 'marea:%'",
      ),
      1,
    );
  } finally {
    await db.close();
  }
});

Deno.test("legacy calls with the same values preserve custom settings", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `select public.set_notification_category('reactions',false);
      select public.set_notification_category('chat',false);
      select public.set_notification_preferences(true,true);`,
    );
    assertEquals(
      await scalar(
        db,
        "select array[chat_enabled,reactions_enabled,marea_enabled,missions_enabled] as value from public.notification_preferences",
      ),
      [false, false, true, true],
    );
  } finally {
    await db.close();
  }
});

Deno.test("auth session revocation and MFA invalidate leased notifications", async () => {
  const db = await database();
  try {
    await ready(db);
    await db.exec(
      `insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
      values('${user}','${actor}','${post}','comment','comment:session','Pieza');`,
    );
    const jobs = await scalar(
      db,
      "select public.claim_push_jobs() as value",
    ) as {
      queue_id: string;
      lease_id: string;
    }[];
    assertEquals(jobs.length, 1);
    const current = `select public.push_job_is_current('${jobs[0].queue_id}','${
      jobs[0].lease_id
    }') as value`;
    await db.exec(`insert into auth.mfa_factors values('${user}','verified');`);
    assertEquals(await scalar(db, current), false);
    await db.exec(`update auth.sessions set aal='aal2' where id='${session}'`);
    assertEquals(await scalar(db, current), true);
    await db.exec(`delete from auth.sessions where id='${session}'`);
    assertEquals(await scalar(db, current), false);
    await assertRejects(() =>
      db.exec(
        `select public.register_notification_device('${device}','valid-length-token-1234',true)`,
      )
    );
  } finally {
    await db.close();
  }
});

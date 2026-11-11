import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
const root = process.env.PGLITE_MODULE_ROOT;
if (!root) throw new Error('Set PGLITE_MODULE_ROOT to the installed @electric-sql/pglite package directory');
const { PGlite } = await import(pathToFileURL(`${root}/dist/index.js`));
const { citext } = await import(pathToFileURL(`${root}/dist/contrib/citext.js`));
import assert from 'node:assert/strict';
const db = new PGlite({extensions:{citext}});
await db.exec(readFileSync(new URL('../../database/schema.sql', import.meta.url),'utf8'));
const columns = (await db.query("select column_name from information_schema.columns where table_name='users'")).rows.map(x=>x.column_name);
for (const field of ['id_google','firebase_uid','email_verified','google_given_name','google_family_name','google_locale']) assert(columns.includes(field), field);
const insert = `INSERT INTO users (email,display_name,id_google,firebase_uid,email_verified) VALUES ($1,'Student',$2,$3,true)`;
await db.query(insert,['first@example.test','google-123','firebase-456']);
for (const [email,google,uid,code] of [
 ['second@example.test','google-123','firebase-other','23505'],
 ['third@example.test','google-other','firebase-456','23505'],
 ['fourth@example.test','','firebase-new','23514'],
 ['fifth@example.test','google-new','  ','23514'],
]) {
 let failure;
 try { await db.query(insert,[email,google,uid]); } catch(e) { failure=e; }
 assert.equal(failure?.code,code);
}
await db.query(insert,['old1@example.test',null,null]);
await db.query(insert,['old2@example.test',null,null]);
const row=(await db.query("SELECT id_google,firebase_uid,email_verified,google_given_name FROM users WHERE email='first@example.test'")).rows[0];
assert.deepEqual(row,{id_google:'google-123',firebase_uid:'firebase-456',email_verified:true,google_given_name:null});
console.log('PASS: full schema execution, six columns, distinct IDs/profile, duplicate Google/Firebase rejection, blank IDs rejection and multiple legacy NULL identities. Local PGlite 0.5.12; no production or multi-connection concurrency claim.');
await db.close();

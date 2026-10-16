// Isolated PostgreSQL/WASM checks. No external account, network or production DB.
// Usage: node database/verify.mjs /absolute/path/to/node_modules/@electric-sql/pglite
import { readFile } from 'node:fs/promises';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import assert from 'node:assert/strict';

const root = dirname(fileURLToPath(import.meta.url));
const pkg = resolve(process.argv[2] ?? 'node_modules/@electric-sql/pglite');
const { PGlite } = await import(pathToFileURL(join(pkg, 'dist/index.js')).href);
const { citext } = await import(pathToFileURL(join(pkg, 'dist/contrib/citext.js')).href);
const packageInfo = JSON.parse(await readFile(join(pkg, 'package.json'), 'utf8'));
let passed = 0;
let db;
async function test(name, fn) {
  try { await fn(); passed++; console.log(`PASS ${name}`); }
  catch (error) { console.error(`FAIL ${name}: ${error.message}`); throw error; }
}
async function reject(sql, match) {
  let error;
  try { await db.transaction(tx => tx.exec(sql)); } catch (caught) { error = caught; }
  assert.ok(error, 'Expected SQL to reject this write');
  if (match) assert.match(error.message, match);
}
const id = n => `'00000000-0000-4000-8000-${String(n).padStart(12, '0')}'`;
const scalar = async sql => Object.values((await db.query(sql)).rows[0])[0];

try {
  db = new PGlite({ extensions: { citext } });
  await test('Original Notion SQL applies', async () => {
    await db.exec(await readFile(join(root, 'source/notion-2026-10-15.sql'), 'utf8'));
    assert.equal(Number(await scalar("SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'")),76);
    assert.equal(Number(await scalar("SELECT count(*) FROM pg_constraint WHERE contype='f' AND connamespace='public'::regnamespace")),141);
    console.log('SOURCE_STATS', JSON.stringify((await db.query("SELECT (SELECT count(*) FROM information_schema.columns WHERE table_schema='public') AS fields")).rows[0]));
  });
  await db.close();
  db = new PGlite({ extensions: { citext } });
  await test('Canonical local SQL applies', async () => {
    await db.exec(await readFile(join(root, 'schema.sql'), 'utf8'));
    assert.equal(Number(await scalar("SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'")),80);
  });
  await test('ERD and dictionary columns/FK count match PostgreSQL catalog',async()=>{
    const expected = JSON.parse(await readFile(join(root,'schema-summary.json'),'utf8'));
    const actual = {};
    for (const row of (await db.query(`SELECT c.table_name,c.column_name FROM information_schema.columns c
      JOIN information_schema.tables t ON t.table_schema=c.table_schema AND t.table_name=c.table_name
      WHERE c.table_schema='public' AND t.table_type='BASE TABLE' ORDER BY c.table_name,c.ordinal_position`)).rows) {
      (actual[row.table_name] ??= []).push(row.column_name);
    }
    assert.deepEqual(actual,expected.tables);
    assert.equal(Number(await scalar("SELECT count(*) FROM pg_constraint WHERE contype='f' AND connamespace='public'::regnamespace")),expected.foreign_key_count);
  });
  console.log('ENGINE', await scalar('SELECT version()'), 'PGlite', packageInfo.version);
  await db.transaction(tx=>tx.exec(`
    INSERT INTO admin_accounts(id,full_name,email) VALUES(${id(1)},'Fixture Admin','admin@example.test');
    INSERT INTO users(id,email,display_name) VALUES(${id(2)},'one@example.test','One'),(${id(3)},'two@example.test','Two');
    INSERT INTO student_profiles(user_id,official_full_name) VALUES(${id(2)},'One'),(${id(3)},'Two');
    INSERT INTO departments(id,code,name_ar) VALUES(${id(4)},'SW','Fixture');
    INSERT INTO academic_years(id,label,starts_on,ends_on) VALUES(${id(5)},'2026/2027','2026-09-01','2027-08-01');
    INSERT INTO terms(id,academic_year_id,semester_in_year,starts_on,ends_on) VALUES(${id(6)},${id(5)},1,'2026-09-01','2027-01-30');
    INSERT INTO learning_containers(id,kind,title_ar,slug,status,pdf_download_policy) VALUES
      (${id(7)},'SUBJECT','Fixture subject','subject','PUBLISHED','DOWNLOADABLE'),
      (${id(8)},'COURSE','Fixture course','course','PUBLISHED','ENCRYPTED_IN_APP');
    INSERT INTO subjects(container_id,code) VALUES(${id(7)},'TEST');
    INSERT INTO course_categories(id,code,name_ar) VALUES(${id(9)},'TEST','Fixture');
    INSERT INTO courses(container_id,category_id) VALUES(${id(8)},${id(9)});
    INSERT INTO lessons(id,container_id,position,title_ar,status) VALUES
      (${id(10)},${id(7)},1,'One','PUBLISHED'),(${id(11)},${id(7)},2,'Draft','DRAFT'),
      (${id(12)},${id(7)},3,'Two','PUBLISHED'),(${id(13)},${id(8)},1,'Course','PUBLISHED');
    INSERT INTO video_assets(id,lesson_id,status) VALUES(${id(14)},${id(10)},'READY'),(${id(15)},${id(13)},'READY');
    INSERT INTO video_renditions(id,video_asset_id,label,width,height,bitrate_kbps,codec,storage_key,size_bytes)
      VALUES(${id(16)},${id(15)},'720p',1280,720,500,'h264','private/fixture',10);
    INSERT INTO devices(id,user_id,device_fingerprint,platform,status) VALUES
      (${id(17)},${id(2)},'test-one','ANDROID','ACTIVE'),(${id(18)},${id(3)},'test-two','IOS','ACTIVE');
    INSERT INTO products(id,kind,name_ar) VALUES(${id(19)},'COURSE','Fixture product');
    INSERT INTO product_course(product_id,course_id,access_duration_days,duration_mode) VALUES(${id(19)},${id(8)},30,'FINITE');
    INSERT INTO payments(id,user_id,product_id,method,status,idempotency_key,paid_at) VALUES
      (${id(20)},${id(2)},${id(19)},'ADMIN_GRANT','PAID','fixture-payment',now());
    INSERT INTO payment_admin_grants(payment_id,granted_by_admin_id,reason) VALUES(${id(20)},${id(1)},'Fixture');
    INSERT INTO entitlements(id,payment_id,starts_at,ends_at) VALUES(${id(21)},${id(20)},now()-interval '1 hour',now()+interval '1 day');
    INSERT INTO grading_schemes(id,subject_id,term_id,version_no,theoretical_weight,practical_weight,theoretical_max,practical_max,pass_mark,approval_source,approved_by_admin_id,approved_at) VALUES
      (${id(22)},${id(7)},${id(6)},1,60,40,100,100,60,'Fixture',${id(1)},now()),
      (${id(23)},${id(7)},${id(6)},2,70,30,100,100,50,'Fixture',${id(1)},now()),
      (${id(24)},${id(7)},${id(6)},3,100,0,100,0,50,'Fixture',${id(1)},now());
    INSERT INTO files(id,storage_provider,bucket,storage_key,original_name,mime_type,size_bytes)
      VALUES(${id(25)},'fixture','private','fixture.pdf','fixture.pdf','application/pdf',10);
    INSERT INTO exercises(id,lesson_id,exercise_type,statement,status) VALUES(${id(26)},${id(10)},'MCQ','Fixture','PUBLISHED');
    INSERT INTO mcq_options(id,exercise_id,position,option_text,is_correct) VALUES(${id(27)},${id(26)},1,'Yes',true);
    INSERT INTO pdf_documents(id,title_ar,is_free,status) VALUES(${id(28)},'Protected',false,'PUBLISHED');
    INSERT INTO container_pdfs(pdf_id,container_id) VALUES(${id(28)},${id(8)});
    INSERT INTO pdf_versions(id,pdf_id,version_no,file_id) VALUES(${id(29)},${id(28)},1,${id(25)});
  `));
  await test('Two-year constraint rejects year 3',()=>reject(`INSERT INTO student_term_enrollments(user_id,term_id,department_id,study_year) VALUES(${id(2)},${id(6)},${id(4)},3)`));
  await test('Only one active device per user',()=>reject(`INSERT INTO devices(user_id,device_fingerprint,platform,status) VALUES(${id(2)},'other','IOS','ACTIVE')`));
  await test('Preview N skips drafts and follows published order',async()=>{
    assert.equal(await scalar(`SELECT is_free_preview FROM v_lesson_preview WHERE lesson_id=${id(12)}`),false);
    await db.exec(`UPDATE learning_containers SET free_preview_count=2 WHERE id=${id(7)}`);
    assert.equal(await scalar(`SELECT is_free_preview FROM v_lesson_preview WHERE lesson_id=${id(12)}`),true);
    assert.equal(Number(await scalar(`SELECT count(*) FROM v_lesson_preview WHERE lesson_id=${id(11)}`)),0);
  });
  const grade=(key,user,scheme,theory,practice,result='PASSED',release='NULL',extra='')=>`INSERT INTO grades(id,user_id,subject_id,term_id,grading_scheme_id,theoretical_mark,practical_mark,result_status,entered_by_admin_id,released_at${extra?',import_row_id':''}) VALUES(${id(key)},${id(user)},${id(7)},${id(6)},${id(scheme)},${theory},${practice},'${result}',${id(1)},${release}${extra?','+extra:''})`;
  await test('60/40 grade normalizes raw marks to 68',async()=>{
    await db.exec(grade(30,2,22,80,50,'PASSED','now()'));
    assert.equal(Number(await scalar(`SELECT total_mark FROM grades WHERE id=${id(30)}`)),68);
  });
  await test('70/30 and 100/0 schemes calculate once',async()=>{
    await db.transaction(async tx=>{
      await tx.exec(grade(31,3,23,60,100));
      assert.equal(Number(Object.values((await tx.query(`SELECT total_mark FROM grades WHERE id=${id(31)}`)).rows[0])[0]),72);
      await tx.exec('DELETE FROM grades WHERE id='+id(31));
      await tx.exec(grade(31,3,24,55,'NULL'));
      assert.equal(Number(Object.values((await tx.query(`SELECT total_mark FROM grades WHERE id=${id(31)}`)).rows[0])[0]),55);
    });
  });
  await test('Invalid component range is rejected',()=>reject(`UPDATE grades SET theoretical_mark=101,change_reason='Fixture' WHERE id=${id(30)}`));
  await test('Pass status must respect subject threshold',()=>reject(`UPDATE grades SET theoretical_mark=1,practical_mark=1,change_reason='Fixture' WHERE id=${id(30)}`));
  await test('Used grading scheme cannot silently change',()=>reject(`UPDATE grading_schemes SET pass_mark=50 WHERE id=${id(22)}`));
  await test('Published grade changes require reason',()=>reject(`UPDATE grades SET theoretical_mark=90 WHERE id=${id(30)}`));
  await test('Published correction retains revision',async()=>{
    await db.exec(`UPDATE grades SET theoretical_mark=90,change_reason='Corrected fixture source' WHERE id=${id(30)}`);
    assert.equal(Number(await scalar('SELECT count(*) FROM grade_revisions')),1);
  });
  await test('Absence remains distinct from mark zero',async()=>{
    await db.exec(`UPDATE grades SET result_status='ABSENT',change_reason='Fixture absence' WHERE id=${id(30)}`);
    assert.equal(await scalar(`SELECT total_mark FROM grades WHERE id=${id(30)}`),null);
  });
  await test('Unreviewed OCR cannot publish a grade',async()=>{
    await db.exec(`INSERT INTO grade_import_batches(id,term_id,file_id,uploaded_by_admin_id) VALUES(${id(32)},${id(6)},${id(25)},${id(1)});
      INSERT INTO grade_import_rows(id,batch_id,row_no,subject_id,matched_user_id,match_status) VALUES(${id(33)},${id(32)},1,${id(7)},${id(2)},'UNMATCHED')`);
    await reject(`UPDATE grades SET import_row_id=${id(33)},result_status='PASSED',change_reason='Fixture OCR' WHERE id=${id(30)}`);
  });
  await test('OCR cannot apply a batch with unresolved rows',()=>reject(`UPDATE grade_import_batches SET status='APPLIED' WHERE id=${id(32)}`));
  await test('Reviewed matched OCR can publish through admin approval',async()=>{
    await db.transaction(tx=>tx.exec(`UPDATE grade_import_rows SET match_status='MATCHED',reviewed_by_admin_id=${id(1)} WHERE id=${id(33)};
      UPDATE grade_import_batches SET status='APPLIED',applied_at=now() WHERE id=${id(32)};
      UPDATE grades SET import_row_id=${id(33)},result_status='PASSED',change_reason='Reviewed OCR source' WHERE id=${id(30)}`));
  });
  await test('Published OCR evidence cannot silently change',()=>reject(`UPDATE grade_import_rows SET matched_user_id=${id(3)} WHERE id=${id(33)}`));
  await test('Published grade cannot be deleted',()=>reject(`DELETE FROM grades WHERE id=${id(30)}`));
  await test('Published MCQ requires a correct option',()=>reject(`INSERT INTO exercises(lesson_id,exercise_type,statement,status) VALUES(${id(10)},'MCQ','Missing answer','PUBLISHED')`));
  await test('Deleting last correct MCQ option is rejected',()=>reject(`DELETE FROM mcq_options WHERE id=${id(27)}`));
  await test('MCQ option cannot move to another exercise',()=>reject(`UPDATE mcq_options SET exercise_id=gen_random_uuid() WHERE id=${id(27)}`));
  await test('Wrong payment detail method is rejected',()=>reject(`INSERT INTO payment_manual_receipts(payment_id,receipt_file_id) VALUES(${id(20)},${id(25)})`));
  await test('Price currency must be explicit while currency policy is open',()=>reject(`INSERT INTO product_prices(product_id,amount) VALUES(${id(19)},10)`));
  await test('Paid payment without verification is rejected',()=>reject(`INSERT INTO payments(user_id,product_id,method,status,idempotency_key,paid_at) VALUES(${id(2)},${id(19)},'ADMIN_GRANT','PAID','bad-fixture',now())`));
  const license=(key,device,asset,grant,expiry)=>`INSERT INTO video_license_requests(id,device_id,video_asset_id,license_type,entitlement_id,is_granted,expires_at) VALUES(${id(key)},${id(device)},${id(asset)},'OFFLINE',${grant},true,${expiry})`;
  await test('DRM grant rejects another user device',()=>reject(license(34,18,15,id(21),"now()+interval '1 hour'")));
  await test('DRM expiry cannot exceed entitlement',()=>reject(license(34,17,15,id(21),"now()+interval '2 days'")));
  await test('Expired preview license cannot be granted',()=>reject(license(34,17,14,'NULL',"now()-interval '1 hour'")));
  await test('Valid offline license can authorize download',async()=>{
    await db.exec(license(34,17,15,id(21),"now()+interval '1 hour'"));
    await db.exec(`INSERT INTO offline_video_downloads(device_id,video_asset_id,rendition_id,entitlement_id,license_request_id) VALUES(${id(17)},${id(15)},${id(16)},${id(21)},${id(34)})`);
  });
  await test('License issuance log is immutable',()=>reject(`UPDATE video_license_requests SET device_id=${id(18)} WHERE id=${id(34)}`));
  await test('Purchased course duration cannot silently change',()=>reject(`UPDATE product_course SET access_duration_days=365 WHERE product_id=${id(19)}`));
  await test('Offline video metadata must match licensed device',()=>reject(`INSERT INTO offline_video_downloads(device_id,video_asset_id,rendition_id,entitlement_id,license_request_id) VALUES(${id(18)},${id(15)},${id(16)},${id(21)},${id(34)})`));
  await test('Course PDF cannot become free',()=>reject(`UPDATE pdf_documents SET is_free=true WHERE id=${id(28)}`));
  await test('Course PDF cannot download without protected license',()=>reject(`INSERT INTO offline_pdf_downloads(device_id,pdf_version_id,entitlement_id) VALUES(${id(17)},${id(29)},${id(21)})`));
  await test('Protected PDF license binds device, version and entitlement',async()=>{
    await db.exec(`INSERT INTO protected_pdf_licenses(id,device_id,pdf_version_id,entitlement_id,expires_at,provider_license_ref) VALUES(${id(35)},${id(17)},${id(29)},${id(21)},now()+interval '1 hour','fixture-ref');
      INSERT INTO offline_pdf_downloads(device_id,pdf_version_id,entitlement_id,license_id) VALUES(${id(17)},${id(29)},${id(21)},${id(35)})`);
  });
  await test('Lesson completion depends on passed exercises, not watching',async()=>{
    await db.exec(`INSERT INTO exercise_attempts(user_id,exercise_id,attempt_no,status,is_passed) VALUES(${id(2)},${id(26)},1,'EVALUATED',true)`);
    assert.equal(await scalar(`SELECT is_completed FROM v_lesson_completion WHERE user_id=${id(2)} AND lesson_id=${id(10)}`),true);
  });
  await test('Revoked entitlement disappears from effective access',async()=>{
    assert.equal(Number(await scalar(`SELECT count(*) FROM v_effective_access WHERE entitlement_id=${id(21)}`)),1);
    await db.exec(`UPDATE entitlements SET status='REVOKED' WHERE id=${id(21)}`);
    assert.equal(Number(await scalar(`SELECT count(*) FROM v_effective_access WHERE entitlement_id=${id(21)}`)),0);
  });
  await test('Revoked entitlement cannot re-activate a download',()=>reject(`UPDATE offline_video_downloads SET status='ACTIVE' WHERE license_request_id=${id(34)}`));
  console.log('LOCAL_STATS',JSON.stringify((await db.query(`SELECT
    (SELECT count(*) FROM pg_constraint WHERE contype='f' AND connamespace='public'::regnamespace) AS foreign_keys,
    (SELECT count(*) FROM pg_views WHERE schemaname='public') AS views,
    (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid WHERE NOT t.tgisinternal AND c.relnamespace='public'::regnamespace) AS triggers`)).rows[0]));
  console.log(`RESULT ${passed} checks passed. No deployment or multi-connection/device/DRM verification.`);
} catch (error) {
  console.error('SQL_VERIFICATION_ERROR', error.code ?? '', error.message);
  process.exitCode = 1;
} finally {
  if (db) await db.close();
}

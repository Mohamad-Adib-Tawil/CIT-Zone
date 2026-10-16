# قاموس قاعدة البيانات المحلي

المخطط المحلي يحتوي 80 جدولاً. تعريفات الصفوف أدناه من SQL المتولد؛ القيود المضافة بـALTER والـViews والـTriggers في schema.sql.

ملفات المصدر الخام تبقى مستقلة في source/. لا يعني توليد القاموس نشر قاعدة إنتاج.

## A-identity

### users

```sql
CREATE TABLE users (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext NOT NULL UNIQUE,
  display_name varchar(150) NOT NULL,
  avatar_url text,
  status user_status NOT NULL DEFAULT 'ACTIVE',
  locale varchar(5) NOT NULL DEFAULT 'ar',
  last_login_at timestamptz,
  terms_accepted_at timestamptz,
  terms_version varchar(20),
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### oauth_identities

```sql
CREATE TABLE oauth_identities (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  provider oauth_provider NOT NULL,
  provider_subject varchar(255) NOT NULL,
  linked_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz,
  UNIQUE (provider, provider_subject),
  UNIQUE (user_id, provider)
);
```

المراجع: `user_id` → `users(id)`

### student_profiles

```sql
CREATE TABLE student_profiles (
user_id uuid PRIMARY KEY,
  official_full_name varchar(150) NOT NULL,
  father_name varchar(80),
  university_student_id varchar(30) UNIQUE,
  phone varchar(20),
  gender gender,
  birth_date date,
  city varchar(80),
  entry_academic_year_id uuid,
  onboarding_completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  legacy_transcript_eligible boolean NOT NULL DEFAULT false
);
```

المراجع: `user_id` → `users(id)`؛ `entry_academic_year_id` → `academic_years(id)`

### user_preferences

```sql
CREATE TABLE user_preferences (
user_id uuid PRIMARY KEY,
  playback_speed numeric(3,2) NOT NULL DEFAULT 1.00,
  auto_play_next boolean NOT NULL DEFAULT true,
  preferred_quality varchar(10),
  wifi_only_downloads boolean NOT NULL DEFAULT true,
  push_enabled boolean NOT NULL DEFAULT true,
  exam_reminders_enabled boolean NOT NULL DEFAULT true,
  theme varchar(10) NOT NULL DEFAULT 'system',
  language varchar(5) NOT NULL DEFAULT 'ar',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `user_id` → `users(id)`

### admin_accounts

```sql
CREATE TABLE admin_accounts (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name varchar(150) NOT NULL,
  email citext NOT NULL UNIQUE,
  password_hash text,
  mfa_secret text,
  role admin_role NOT NULL DEFAULT 'ADMIN',
  is_active boolean NOT NULL DEFAULT true,
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### devices

```sql
CREATE TABLE devices (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  device_fingerprint varchar(255) NOT NULL,
  platform platform NOT NULL,
  manufacturer varchar(60),
  model varchar(80),
  os_version varchar(30),
  app_version varchar(20),
  push_token text,
  status device_status NOT NULL DEFAULT 'PENDING',
  bound_at timestamptz,
  authorized_by_admin_id uuid,
  revoked_at timestamptz,
  revoke_reason varchar(255),
  last_seen_at timestamptz,
  last_ip inet,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, device_fingerprint)
);
```

المراجع: `user_id` → `users(id)`؛ `authorized_by_admin_id` → `admin_accounts(id)`

### device_change_requests

```sql
CREATE TABLE device_change_requests (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  new_device_id uuid NOT NULL,
  old_device_id uuid,
  conversation_id uuid,
  reason text,
  status request_status NOT NULL DEFAULT 'PENDING',
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_by_admin_id uuid,
  decided_at timestamptz,
  decision_note text
);
```

المراجع: `new_device_id` → `devices(id)`؛ `old_device_id` → `devices(id)`؛ `conversation_id` → `support_conversations(id)`؛ `decided_by_admin_id` → `admin_accounts(id)`

### auth_sessions

```sql
CREATE TABLE auth_sessions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  refresh_token_hash varchar(128) NOT NULL UNIQUE,
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  last_used_at timestamptz,
  revoked_at timestamptz,
  revoked_reason varchar(100),
  ip inet,
  user_agent text
);
```

المراجع: `device_id` → `devices(id)`

### security_events

```sql
CREATE TABLE security_events (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  device_id uuid,
  kind security_event_kind NOT NULL,
  severity severity NOT NULL DEFAULT 'LOW',
  details jsonb,
  ip inet,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by_admin_id uuid,
  reviewed_at timestamptz
);
```

المراجع: `user_id` → `users(id)`؛ `device_id` → `devices(id)`؛ `reviewed_by_admin_id` → `admin_accounts(id)`

## B-academic

### departments

```sql
CREATE TABLE departments (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(20) NOT NULL UNIQUE,
  name_ar varchar(100) NOT NULL,
  name_en varchar(100),
  description text,
  sort_order smallint NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### academic_years

```sql
CREATE TABLE academic_years (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label varchar(9) NOT NULL UNIQUE,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  is_current boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_on > starts_on)
);
```

### terms

```sql
CREATE TABLE terms (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL,
  semester_in_year smallint NOT NULL,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  exams_start_on date,
  exams_end_on date,
  status term_status NOT NULL DEFAULT 'UPCOMING',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (academic_year_id, semester_in_year),
  CHECK (semester_in_year IN (1,2)),
  CHECK (ends_on > starts_on)
);
```

المراجع: `academic_year_id` → `academic_years(id)`

### student_term_enrollments

```sql
CREATE TABLE student_term_enrollments (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  term_id uuid NOT NULL,
  department_id uuid NOT NULL,
  study_year smallint NOT NULL,
  status enrollment_status NOT NULL DEFAULT 'ACTIVE',
  confirmed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, term_id),
  CHECK (study_year BETWEEN 1 AND 2)
);
```

المراجع: `user_id` → `users(id)`؛ `term_id` → `terms(id)`؛ `department_id` → `departments(id)`

### department_subjects

```sql
CREATE TABLE department_subjects (
department_id uuid,
  subject_id uuid,
  study_year smallint NOT NULL,
  semester_in_year smallint NOT NULL,
  position smallint NOT NULL DEFAULT 0,
  is_required boolean NOT NULL DEFAULT true,
  counts_toward_progress boolean NOT NULL DEFAULT true,
  PRIMARY KEY (department_id, subject_id, study_year, semester_in_year),
  CHECK (semester_in_year IN (1,2))
);
```

المراجع: `department_id` → `departments(id)`؛ `subject_id` → `subjects(container_id)`

### exam_schedules

```sql
CREATE TABLE exam_schedules (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  term_id uuid NOT NULL,
  subject_id uuid NOT NULL,
  session exam_session NOT NULL DEFAULT 'REGULAR',
  kind exam_kind NOT NULL,
  starts_at timestamptz NOT NULL,
  location varchar(120),
  notes text,
  created_by_admin_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (term_id, subject_id, session, kind)
);
```

المراجع: `term_id` → `terms(id)`؛ `subject_id` → `subjects(container_id)`؛ `created_by_admin_id` → `admin_accounts(id)`

## C-content

### learning_containers

```sql
CREATE TABLE learning_containers (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind container_kind NOT NULL,
  title_ar varchar(200) NOT NULL,
  title_en varchar(200),
  slug varchar(120) NOT NULL UNIQUE,
  summary varchar(300),
  description text,
  cover_file_id uuid,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  pdf_download_policy pdf_download_policy NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  published_at timestamptz,
  created_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, kind),
  free_preview_count integer NOT NULL DEFAULT 1 CHECK (free_preview_count >= 1)
);
```

المراجع: `cover_file_id` → `files(id)`؛ `created_by_admin_id` → `admin_accounts(id)`

### subjects

```sql
CREATE TABLE subjects (
container_id uuid PRIMARY KEY,
  kind container_kind NOT NULL DEFAULT 'SUBJECT',
  code varchar(20) NOT NULL UNIQUE,
  credit_hours smallint,
  is_graduation_project boolean NOT NULL DEFAULT false,
  CHECK (kind = 'SUBJECT')
);
```

المراجع: `container_id,kind` → `learning_containers(id,kind)`

### course_categories

```sql
CREATE TABLE course_categories (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(30) NOT NULL UNIQUE,
  name_ar varchar(100) NOT NULL,
  name_en varchar(100),
  icon varchar(50),
  sort_order smallint NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true
);
```

### courses

```sql
CREATE TABLE courses (
container_id uuid PRIMARY KEY,
  kind container_kind NOT NULL DEFAULT 'COURSE',
  category_id uuid NOT NULL,
  level course_level NOT NULL DEFAULT 'BEGINNER',
  estimated_hours numeric(5,1),
  prerequisites text,
  CHECK (kind = 'COURSE')
);
```

المراجع: `category_id` → `course_categories(id)`؛ `container_id,kind` → `learning_containers(id,kind)`

### course_outcomes

```sql
CREATE TABLE course_outcomes (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL,
  position smallint NOT NULL,
  text_ar varchar(255) NOT NULL,
  UNIQUE (course_id, position)
);
```

المراجع: `course_id` → `courses(container_id)`

### lessons

```sql
CREATE TABLE lessons (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  container_id uuid NOT NULL,
  position int NOT NULL,
  title_ar varchar(200) NOT NULL,
  title_en varchar(200),
  description text,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (container_id, position)
);
```

المراجع: `container_id` → `learning_containers(id)`

### video_assets

```sql
CREATE TABLE video_assets (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id uuid NOT NULL UNIQUE,
  status video_status NOT NULL DEFAULT 'UPLOADING',
  source_file_id uuid,
  duration_seconds int,
  packaging varchar(20),
  manifest_path varchar(500),
  drm_provider varchar(30),
  drm_key_id varchar(100),
  thumbnail_file_id uuid,
  processing_error text,
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `lesson_id` → `lessons(id)`؛ `source_file_id` → `files(id)`؛ `thumbnail_file_id` → `files(id)`

### video_renditions

```sql
CREATE TABLE video_renditions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_asset_id uuid NOT NULL,
  label varchar(10) NOT NULL,
  width int NOT NULL,
  height int NOT NULL,
  bitrate_kbps int NOT NULL,
  codec varchar(20) NOT NULL,
  storage_key varchar(500) NOT NULL,
  size_bytes bigint NOT NULL,
  UNIQUE (video_asset_id, label)
);
```

المراجع: `video_asset_id` → `video_assets(id)`

### video_subtitles

```sql
CREATE TABLE video_subtitles (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_asset_id uuid NOT NULL,
  language_code varchar(5) NOT NULL,
  label varchar(40) NOT NULL,
  file_id uuid NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  UNIQUE (video_asset_id, language_code)
);
```

المراجع: `video_asset_id` → `video_assets(id)`؛ `file_id` → `files(id)`

### pdf_documents

```sql
CREATE TABLE pdf_documents (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar varchar(200) NOT NULL,
  description text,
  is_free boolean NOT NULL,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  position int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### pdf_versions

```sql
CREATE TABLE pdf_versions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pdf_id uuid NOT NULL,
  version_no int NOT NULL,
  file_id uuid NOT NULL,
  page_count int,
  is_current boolean NOT NULL DEFAULT true,
  change_note text,
  created_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (pdf_id, version_no)
);
```

المراجع: `pdf_id` → `pdf_documents(id)`؛ `file_id` → `files(id)`؛ `created_by_admin_id` → `admin_accounts(id)`

### container_pdfs

```sql
CREATE TABLE container_pdfs (
pdf_id uuid PRIMARY KEY,
  container_id uuid NOT NULL
);
```

المراجع: `pdf_id` → `pdf_documents(id)`؛ `container_id` → `learning_containers(id)`

### lesson_pdfs

```sql
CREATE TABLE lesson_pdfs (
pdf_id uuid PRIMARY KEY,
  lesson_id uuid NOT NULL
);
```

المراجع: `pdf_id` → `pdf_documents(id)`؛ `lesson_id` → `lessons(id)`

### content_contributors

```sql
CREATE TABLE content_contributors (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name varchar(150) NOT NULL,
  headline varchar(150),
  user_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `user_id` → `users(id)`

### pdf_contributors

```sql
CREATE TABLE pdf_contributors (
pdf_id uuid,
  contributor_id uuid,
  role contributor_role DEFAULT 'AUTHOR',
  PRIMARY KEY (pdf_id, contributor_id, role)
);
```

المراجع: `pdf_id` → `pdf_documents(id)`؛ `contributor_id` → `content_contributors(id)`

## D-exercises

### exercises

```sql
CREATE TABLE exercises (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id uuid NOT NULL,
  exercise_type exercise_type NOT NULL,
  title varchar(200),
  statement text NOT NULL,
  explanation text,
  hint text,
  difficulty difficulty NOT NULL DEFAULT 'MEDIUM',
  max_points smallint NOT NULL DEFAULT 1,
  position int NOT NULL DEFAULT 0,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `lesson_id` → `lessons(id)`

### mcq_options

```sql
CREATE TABLE mcq_options (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id uuid NOT NULL,
  position smallint NOT NULL,
  option_text text NOT NULL,
  is_correct boolean NOT NULL DEFAULT false,
  feedback text,
  UNIQUE (exercise_id, position)
);
```

المراجع: `exercise_id` → `exercises(id)`

### code_exercise_specs

```sql
CREATE TABLE code_exercise_specs (
exercise_id uuid PRIMARY KEY,
  programming_language varchar(30) NOT NULL,
  starter_code text,
  reference_solution text,
  grading_instructions text NOT NULL,
  expected_behavior text,
  max_code_length int NOT NULL DEFAULT 8000
);
```

المراجع: `exercise_id` → `exercises(id)`

### exercise_attempts

```sql
CREATE TABLE exercise_attempts (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  exercise_id uuid NOT NULL,
  attempt_no int NOT NULL,
  status attempt_status NOT NULL DEFAULT 'SUBMITTED',
  is_passed boolean,
  score numeric(5,2),
  time_spent_seconds int,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  evaluated_at timestamptz,
  UNIQUE (user_id, exercise_id, attempt_no)
);
```

المراجع: `user_id` → `users(id)`؛ `exercise_id` → `exercises(id)`

### attempt_mcq_choices

```sql
CREATE TABLE attempt_mcq_choices (
attempt_id uuid PRIMARY KEY,
  option_id uuid NOT NULL
);
```

المراجع: `attempt_id` → `exercise_attempts(id)`؛ `option_id` → `mcq_options(id)`

### code_submissions

```sql
CREATE TABLE code_submissions (
attempt_id uuid PRIMARY KEY,
  source_code text NOT NULL,
  programming_language varchar(30) NOT NULL
);
```

المراجع: `attempt_id` → `exercise_attempts(id)`

### ai_evaluations

```sql
CREATE TABLE ai_evaluations (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL,
  model_name varchar(60) NOT NULL,
  prompt_version varchar(20) NOT NULL,
  verdict ai_verdict NOT NULL,
  score numeric(5,2),
  explanation text,
  suggested_fix text,
  raw_response jsonb,
  prompt_tokens int,
  completion_tokens int,
  latency_ms int,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `attempt_id` → `code_submissions(attempt_id)`

### ai_evaluation_findings

```sql
CREATE TABLE ai_evaluation_findings (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_id uuid NOT NULL,
  line_start int,
  line_end int,
  severity finding_severity NOT NULL DEFAULT 'ERROR',
  message text NOT NULL
);
```

المراجع: `evaluation_id` → `ai_evaluations(id)`

## E-offline

### lesson_watch_progress

```sql
CREATE TABLE lesson_watch_progress (
user_id uuid,
  lesson_id uuid,
  last_position_seconds int NOT NULL DEFAULT 0,
  total_watched_seconds int NOT NULL DEFAULT 0,
  first_watched_at timestamptz NOT NULL DEFAULT now(),
  last_watched_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, lesson_id)
);
```

المراجع: `user_id` → `users(id)`؛ `lesson_id` → `lessons(id)`

### lesson_ratings

```sql
CREATE TABLE lesson_ratings (
user_id uuid,
  lesson_id uuid,
  stars smallint NOT NULL,
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, lesson_id),
  CHECK (stars BETWEEN 1 AND 5)
);
```

المراجع: `user_id` → `users(id)`؛ `lesson_id` → `lessons(id)`

### usage_sessions

```sql
CREATE TABLE usage_sessions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  started_at timestamptz NOT NULL,
  last_heartbeat_at timestamptz NOT NULL,
  ended_at timestamptz,
  active_seconds int NOT NULL DEFAULT 0,
  app_version varchar(20)
);
```

المراجع: `device_id` → `devices(id)`

### video_license_requests

```sql
CREATE TABLE video_license_requests (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  video_asset_id uuid NOT NULL,
  license_type license_type NOT NULL,
  entitlement_id uuid,
  is_granted boolean NOT NULL,
  denial_reason varchar(100),
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  ip inet
);
```

المراجع: `device_id` → `devices(id)`؛ `video_asset_id` → `video_assets(id)`؛ `entitlement_id` → `entitlements(id)`

### offline_video_downloads

```sql
CREATE TABLE offline_video_downloads (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  video_asset_id uuid NOT NULL,
  rendition_id uuid NOT NULL,
  entitlement_id uuid,
  status offline_status NOT NULL DEFAULT 'ACTIVE',
  downloaded_at timestamptz NOT NULL DEFAULT now(),
  last_verified_at timestamptz,
  removed_at timestamptz,
  UNIQUE (device_id, video_asset_id),
  license_request_id uuid NOT NULL REFERENCES video_license_requests(id)
);
```

المراجع: `license_request_id` → `video_license_requests(id)`؛ `device_id` → `devices(id)`؛ `video_asset_id` → `video_assets(id)`؛ `rendition_id` → `video_renditions(id)`؛ `entitlement_id` → `entitlements(id)`

### offline_pdf_downloads

```sql
CREATE TABLE offline_pdf_downloads (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  pdf_version_id uuid NOT NULL,
  entitlement_id uuid,
  status offline_status NOT NULL DEFAULT 'ACTIVE',
  downloaded_at timestamptz NOT NULL DEFAULT now(),
  last_verified_at timestamptz,
  removed_at timestamptz,
  UNIQUE (device_id, pdf_version_id),
  license_id uuid REFERENCES protected_pdf_licenses(id)
);
```

المراجع: `license_id` → `protected_pdf_licenses(id)`؛ `device_id` → `devices(id)`؛ `pdf_version_id` → `pdf_versions(id)`؛ `entitlement_id` → `entitlements(id)`

### device_time_syncs

```sql
CREATE TABLE device_time_syncs (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  server_time timestamptz NOT NULL,
  device_time timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `device_id` → `devices(id)`

### protected_pdf_licenses

```sql
CREATE TABLE protected_pdf_licenses (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL REFERENCES devices(id),
  pdf_version_id uuid NOT NULL REFERENCES pdf_versions(id),
  entitlement_id uuid NOT NULL REFERENCES entitlements(id),
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  provider_license_ref text NOT NULL,
  CHECK (expires_at > issued_at)
);
```

المراجع: `device_id` → `devices(id)`؛ `pdf_version_id` → `pdf_versions(id)`؛ `entitlement_id` → `entitlements(id)`

## F-commerce

### products

```sql
CREATE TABLE products (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind product_kind NOT NULL,
  name_ar varchar(200) NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  available_from timestamptz,
  available_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, kind)
);
```

### product_prices

```sql
CREATE TABLE product_prices (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL,
  amount numeric(14,2) NOT NULL,
  currency char(3) NOT NULL,
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_to timestamptz,
  created_by_admin_id uuid,
  UNIQUE (product_id, currency, effective_from),
  CHECK (amount >= 0)
);
```

المراجع: `product_id` → `products(id)`؛ `created_by_admin_id` → `admin_accounts(id)`

### product_subject_term

```sql
CREATE TABLE product_subject_term (
product_id uuid PRIMARY KEY,
  kind product_kind NOT NULL DEFAULT 'SUBJECT_TERM',
  subject_id uuid NOT NULL,
  term_id uuid NOT NULL,
  UNIQUE (subject_id, term_id),
  CHECK (kind = 'SUBJECT_TERM')
);
```

المراجع: `subject_id` → `subjects(container_id)`؛ `term_id` → `terms(id)`؛ `product_id,kind` → `products(id,kind)`

### product_semester_bundle

```sql
CREATE TABLE product_semester_bundle (
product_id uuid PRIMARY KEY,
  kind product_kind NOT NULL DEFAULT 'SEMESTER_BUNDLE',
  term_id uuid NOT NULL,
  department_id uuid NOT NULL,
  study_year smallint NOT NULL,
  UNIQUE (term_id, department_id, study_year),
  CHECK (kind = 'SEMESTER_BUNDLE')
);
```

المراجع: `term_id` → `terms(id)`؛ `department_id` → `departments(id)`؛ `product_id,kind` → `products(id,kind)`

### product_course

```sql
CREATE TABLE product_course (
product_id uuid PRIMARY KEY,
  kind product_kind NOT NULL DEFAULT 'COURSE',
  course_id uuid NOT NULL,
  access_duration_days int,
  CHECK (kind = 'COURSE'),
  duration_mode text NOT NULL
  CHECK (duration_mode IN ('FINITE', 'LIFETIME'))
);
```

المراجع: `course_id` → `courses(container_id)`؛ `product_id,kind` → `products(id,kind)`

### payments

```sql
CREATE TABLE payments (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL,
  price_id uuid,
  method payment_method NOT NULL,
  status payment_status NOT NULL DEFAULT 'PENDING',
  idempotency_key varchar(64) NOT NULL UNIQUE,
  expires_at timestamptz,
  paid_at timestamptz,
  failure_reason varchar(255),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((method = 'ADMIN_GRANT') = (price_id IS NULL))
);
```

المراجع: `user_id` → `users(id)`؛ `product_id` → `products(id)`؛ `price_id` → `product_prices(id)`؛ `price_id, product_id` → `product_prices(id, product_id)`

### payment_shamcash

```sql
CREATE TABLE payment_shamcash (
payment_id uuid PRIMARY KEY,
  shamcash_tx_id varchar(100) NOT NULL UNIQUE,
  payer_account varchar(60) NOT NULL,
  payer_name varchar(150),
  receiver_account varchar(60) NOT NULL,
  reported_amount numeric(14,2) NOT NULL,
  reported_currency char(3) NOT NULL,
  gateway_status varchar(30) NOT NULL,
  raw_payload jsonb,
  verified_at timestamptz
);
```

المراجع: `payment_id` → `payments(id)`

### payment_manual_receipts

```sql
CREATE TABLE payment_manual_receipts (
payment_id uuid PRIMARY KEY,
  receipt_file_id uuid NOT NULL,
  claimed_tx_ref varchar(100),
  claimed_amount numeric(14,2),
  claimed_paid_at timestamptz,
  review_status review_status NOT NULL DEFAULT 'PENDING',
  reviewed_by_admin_id uuid,
  reviewed_at timestamptz,
  rejection_reason text,
  submitted_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `payment_id` → `payments(id)`؛ `receipt_file_id` → `files(id)`؛ `reviewed_by_admin_id` → `admin_accounts(id)`

### payment_admin_grants

```sql
CREATE TABLE payment_admin_grants (
payment_id uuid PRIMARY KEY,
  granted_by_admin_id uuid NOT NULL,
  reason text NOT NULL
);
```

المراجع: `payment_id` → `payments(id)`؛ `granted_by_admin_id` → `admin_accounts(id)`

### voucher_outlets

```sql
CREATE TABLE voucher_outlets (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(150) NOT NULL,
  contact_name varchar(100),
  phone varchar(20),
  address text,
  commission_percent numeric(5,2),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### voucher_batches

```sql
CREATE TABLE voucher_batches (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  outlet_id uuid,
  product_id uuid NOT NULL,
  quantity int NOT NULL,
  printed_at timestamptz NOT NULL DEFAULT now(),
  expires_on date,
  created_by_admin_id uuid NOT NULL,
  notes text
);
```

المراجع: `outlet_id` → `voucher_outlets(id)`؛ `product_id` → `products(id)`؛ `created_by_admin_id` → `admin_accounts(id)`

### vouchers

```sql
CREATE TABLE vouchers (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL,
  serial_no varchar(30) NOT NULL UNIQUE,
  code_hash varchar(128) NOT NULL UNIQUE,
  status voucher_status NOT NULL DEFAULT 'PRINTED',
  activated_at timestamptz,
  redeemed_payment_id uuid UNIQUE,
  redeemed_at timestamptz,
  voided_at timestamptz,
  void_reason varchar(255)
);
```

المراجع: `batch_id` → `voucher_batches(id)`؛ `redeemed_payment_id` → `payments(id)`

### entitlements

```sql
CREATE TABLE entitlements (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id uuid NOT NULL UNIQUE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  status entitlement_status NOT NULL DEFAULT 'ACTIVE',
  revoked_at timestamptz,
  revoked_by_admin_id uuid,
  revoke_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `payment_id` → `payments(id)`؛ `revoked_by_admin_id` → `admin_accounts(id)`

### product_bundle_subjects

```sql
CREATE TABLE product_bundle_subjects (
product_id uuid NOT NULL REFERENCES product_semester_bundle(product_id),
  subject_id uuid NOT NULL REFERENCES subjects(container_id),
  PRIMARY KEY (product_id, subject_id)
);
```

المراجع: `product_id` → `product_semester_bundle(product_id)`؛ `subject_id` → `subjects(container_id)`

## G-grades

### grade_import_batches

```sql
CREATE TABLE grade_import_batches (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  term_id uuid NOT NULL,
  session exam_session NOT NULL DEFAULT 'REGULAR',
  file_id uuid NOT NULL,
  status import_status NOT NULL DEFAULT 'UPLOADED',
  ocr_engine varchar(40),
  error_message text,
  uploaded_by_admin_id uuid NOT NULL,
  applied_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `term_id` → `terms(id)`؛ `file_id` → `files(id)`؛ `uploaded_by_admin_id` → `admin_accounts(id)`

### grade_import_rows

```sql
CREATE TABLE grade_import_rows (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL,
  row_no int NOT NULL,
  raw_university_id varchar(30),
  raw_student_name varchar(200),
  subject_id uuid,
  practical_mark numeric(5,2),
  theoretical_mark numeric(5,2),
  raw_result varchar(30),
  matched_user_id uuid,
  match_status match_status NOT NULL DEFAULT 'UNMATCHED',
  confidence numeric(4,3),
  reviewed_by_admin_id uuid,
  UNIQUE (batch_id, row_no)
);
```

المراجع: `batch_id` → `grade_import_batches(id)`؛ `subject_id` → `subjects(container_id)`؛ `matched_user_id` → `users(id)`؛ `reviewed_by_admin_id` → `admin_accounts(id)`

### transcript_submissions

```sql
CREATE TABLE transcript_submissions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  file_id uuid NOT NULL,
  covers_through_term_id uuid,
  status review_status NOT NULL DEFAULT 'PENDING',
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by_admin_id uuid,
  reviewed_at timestamptz,
  rejection_reason text,
  notes text
);
```

المراجع: `user_id` → `users(id)`؛ `file_id` → `files(id)`؛ `covers_through_term_id` → `terms(id)`؛ `reviewed_by_admin_id` → `admin_accounts(id)`

### grades

```sql
CREATE TABLE grades (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  subject_id uuid NOT NULL,
  term_id uuid NOT NULL,
  session exam_session NOT NULL DEFAULT 'REGULAR',
  practical_mark numeric(5,2),
  theoretical_mark numeric(5,2),
  total_mark numeric(5,2), -- Set by validate_grade(), using an immutable grading scheme.
  result_status result_status NOT NULL DEFAULT 'PENDING',
  released_at timestamptz,
  import_row_id uuid UNIQUE,
  transcript_submission_id uuid,
  entered_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, subject_id, term_id, session),
  CHECK (num_nonnulls(import_row_id, transcript_submission_id) <= 1),
  grading_scheme_id uuid NOT NULL,
  change_reason text
);
```

المراجع: `user_id` → `users(id)`؛ `subject_id` → `subjects(container_id)`؛ `term_id` → `terms(id)`؛ `import_row_id` → `grade_import_rows(id)`؛ `transcript_submission_id` → `transcript_submissions(id)`؛ `entered_by_admin_id` → `admin_accounts(id)`؛ `grading_scheme_id, subject_id, term_id` → `grading_schemes(id, subject_id, term_id)`

### grade_report_exports

```sql
CREATE TABLE grade_report_exports (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  term_id uuid,
  file_id uuid,
  generated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `user_id` → `users(id)`؛ `term_id` → `terms(id)`؛ `file_id` → `files(id)`

### grading_schemes

```sql
CREATE TABLE grading_schemes (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id uuid NOT NULL REFERENCES subjects(container_id),
  term_id uuid NOT NULL REFERENCES terms(id),
  version_no integer NOT NULL CHECK (version_no > 0),
  theoretical_weight numeric(5,2) NOT NULL CHECK (theoretical_weight BETWEEN 0 AND 100),
  practical_weight numeric(5,2) NOT NULL CHECK (practical_weight BETWEEN 0 AND 100),
  theoretical_max numeric(7,2) NOT NULL CHECK (theoretical_max > 0),
  practical_max numeric(7,2) NOT NULL CHECK (practical_max >= 0),
  pass_mark smallint NOT NULL CHECK (pass_mark IN (50,60)),
  approval_source text NOT NULL CHECK (length(trim(approval_source)) > 0),
  approved_by_admin_id uuid NOT NULL REFERENCES admin_accounts(id),
  approved_at timestamptz NOT NULL,
  UNIQUE (subject_id, term_id, version_no),
  UNIQUE (id, subject_id, term_id),
  CHECK (theoretical_weight + practical_weight = 100),
  CHECK ((practical_weight = 0 AND practical_max = 0) OR (practical_weight > 0 AND practical_max > 0))
);
```

المراجع: `subject_id` → `subjects(container_id)`؛ `term_id` → `terms(id)`؛ `approved_by_admin_id` → `admin_accounts(id)`

### grade_revisions

```sql
CREATE TABLE grade_revisions (
id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  grade_id uuid NOT NULL REFERENCES grades(id),
  changed_by_admin_id uuid NOT NULL REFERENCES admin_accounts(id),
  reason text NOT NULL CHECK (length(trim(reason)) > 0),
  previous_record jsonb NOT NULL,
  new_record jsonb NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `grade_id` → `grades(id)`؛ `changed_by_admin_id` → `admin_accounts(id)`

## H-communication

### announcements

```sql
CREATE TABLE announcements (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title varchar(250) NOT NULL,
  body text NOT NULL,
  source announcement_source NOT NULL DEFAULT 'UNIVERSITY_OFFICIAL',
  source_url text,
  cover_file_id uuid,
  is_pinned boolean NOT NULL DEFAULT false,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  published_at timestamptz,
  expires_at timestamptz,
  created_by_admin_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `cover_file_id` → `files(id)`؛ `created_by_admin_id` → `admin_accounts(id)`

### announcement_attachments

```sql
CREATE TABLE announcement_attachments (
announcement_id uuid,
  file_id uuid,
  position smallint NOT NULL DEFAULT 0,
  caption varchar(200),
  PRIMARY KEY (announcement_id, file_id)
);
```

المراجع: `announcement_id` → `announcements(id)`؛ `file_id` → `files(id)`

### notification_templates

```sql
CREATE TABLE notification_templates (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(40) NOT NULL UNIQUE,
  title_pattern varchar(200) NOT NULL,
  body_pattern text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### notifications

```sql
CREATE TABLE notifications (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind notification_kind NOT NULL,
  template_id uuid NOT NULL,
  title varchar(200) NOT NULL,
  body text NOT NULL,
  deep_link varchar(255),
  audience_kind audience_kind NOT NULL DEFAULT 'ALL',
  department_id uuid,
  container_id uuid,
  exam_schedule_id uuid,
  announcement_id uuid,
  scheduled_for timestamptz,
  sent_at timestamptz,
  created_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((audience_kind = 'DEPARTMENT') = (department_id IS NOT NULL))
);
```

المراجع: `template_id` → `notification_templates(id)`؛ `department_id` → `departments(id)`؛ `container_id` → `learning_containers(id)`؛ `exam_schedule_id` → `exam_schedules(id)`؛ `announcement_id` → `announcements(id)`؛ `created_by_admin_id` → `admin_accounts(id)`

### notification_recipients

```sql
CREATE TABLE notification_recipients (
notification_id uuid,
  user_id uuid,
  delivery_status delivery_status NOT NULL DEFAULT 'PENDING',
  delivered_at timestamptz,
  read_at timestamptz,
  error_message varchar(255),
  PRIMARY KEY (notification_id, user_id)
);
```

المراجع: `notification_id` → `notifications(id)`؛ `user_id` → `users(id)`

### support_conversations

```sql
CREATE TABLE support_conversations (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  topic conversation_topic NOT NULL DEFAULT 'GENERAL',
  subject varchar(200),
  status conversation_status NOT NULL DEFAULT 'OPEN',
  assigned_admin_id uuid,
  last_message_at timestamptz,
  resolved_at timestamptz,
  satisfaction_rating smallint,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `user_id` → `users(id)`؛ `assigned_admin_id` → `admin_accounts(id)`

### support_messages

```sql
CREATE TABLE support_messages (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_admin_id uuid,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);
```

المراجع: `conversation_id` → `support_conversations(id)`؛ `sender_admin_id` → `admin_accounts(id)`

### support_message_attachments

```sql
CREATE TABLE support_message_attachments (
message_id uuid,
  file_id uuid,
  PRIMARY KEY (message_id, file_id)
);
```

المراجع: `message_id` → `support_messages(id)`؛ `file_id` → `files(id)`

## I-system

### files

```sql
CREATE TABLE files (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_provider varchar(20) NOT NULL,
  bucket varchar(100) NOT NULL,
  storage_key varchar(500) NOT NULL,
  original_name varchar(255) NOT NULL,
  mime_type varchar(100) NOT NULL,
  size_bytes bigint NOT NULL,
  checksum_sha256 char(64),
  is_private boolean NOT NULL DEFAULT true,
  uploaded_by_user_id uuid,
  uploaded_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bucket, storage_key),
  CHECK (num_nonnulls(uploaded_by_user_id, uploaded_by_admin_id) <= 1)
);
```

المراجع: `uploaded_by_user_id` → `users(id)`؛ `uploaded_by_admin_id` → `admin_accounts(id)`

### admin_audit_logs

```sql
CREATE TABLE admin_audit_logs (
id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  admin_id uuid NOT NULL,
  action varchar(60) NOT NULL,
  entity_type varchar(60) NOT NULL,
  entity_id varchar(64),
  changes jsonb,
  ip inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `admin_id` → `admin_accounts(id)`

### feature_flags

```sql
CREATE TABLE feature_flags (
key varchar(60) PRIMARY KEY,
  is_enabled boolean NOT NULL DEFAULT false,
  description text,
  updated_by_admin_id uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `updated_by_admin_id` → `admin_accounts(id)`

### app_settings

```sql
CREATE TABLE app_settings (
key varchar(60) PRIMARY KEY,
  value jsonb NOT NULL,
  description text,
  updated_by_admin_id uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

المراجع: `updated_by_admin_id` → `admin_accounts(id)`

### app_versions

```sql
CREATE TABLE app_versions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform platform NOT NULL,
  version_name varchar(20) NOT NULL,
  build_number int NOT NULL,
  min_supported_build int NOT NULL,
  is_force_update boolean NOT NULL DEFAULT false,
  store_url text,
  release_notes text,
  released_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (platform, build_number)
);
```

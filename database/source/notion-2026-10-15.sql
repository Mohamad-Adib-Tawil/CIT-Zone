-- Extracted SQL code blocks, in source order. No corrections. Source: Notion export 2026-10-15.

CREATE EXTENSION IF NOT EXISTS citext;

CREATE TYPE user_status AS ENUM ('ACTIVE', 'SUSPENDED', 'DELETED');
CREATE TYPE gender AS ENUM ('MALE', 'FEMALE');
CREATE TYPE oauth_provider AS ENUM ('GOOGLE');
CREATE TYPE admin_role AS ENUM ('ADMIN');
CREATE TYPE platform AS ENUM ('ANDROID', 'IOS');
CREATE TYPE device_status AS ENUM ('PENDING', 'ACTIVE', 'REVOKED');
CREATE TYPE request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
CREATE TYPE security_event_kind AS ENUM ('NEW_DEVICE_LOGIN_BLOCKED', 'CLOCK_ROLLBACK', 'SCREEN_CAPTURE_ATTEMPT', 'ROOTED_OR_JAILBROKEN', 'REFRESH_TOKEN_REUSE', 'DRM_LICENSE_DENIED', 'OTHER');
CREATE TYPE severity AS ENUM ('LOW', 'MEDIUM', 'HIGH');
CREATE TYPE term_status AS ENUM ('UPCOMING', 'ACTIVE', 'CLOSED');
CREATE TYPE enrollment_status AS ENUM ('ACTIVE', 'GRADUATED', 'WITHDRAWN', 'POSTPONED');
CREATE TYPE exam_session AS ENUM ('REGULAR', 'SUPPLEMENTARY');
CREATE TYPE exam_kind AS ENUM ('THEORETICAL', 'PRACTICAL');
CREATE TYPE container_kind AS ENUM ('SUBJECT', 'COURSE');
CREATE TYPE publish_status AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');
CREATE TYPE pdf_download_policy AS ENUM ('DOWNLOADABLE', 'VIEW_ONLY');
CREATE TYPE course_level AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED');
CREATE TYPE video_status AS ENUM ('UPLOADING', 'PROCESSING', 'READY', 'FAILED');
CREATE TYPE contributor_role AS ENUM ('AUTHOR', 'REVIEWER');
CREATE TYPE exercise_type AS ENUM ('MCQ', 'CODE');
CREATE TYPE difficulty AS ENUM ('EASY', 'MEDIUM', 'HARD');
CREATE TYPE attempt_status AS ENUM ('SUBMITTED', 'EVALUATING', 'EVALUATED', 'EVALUATION_FAILED');
CREATE TYPE ai_verdict AS ENUM ('CORRECT', 'PARTIAL', 'INCORRECT', 'INCONCLUSIVE');
CREATE TYPE finding_severity AS ENUM ('ERROR', 'WARNING', 'HINT');
CREATE TYPE license_type AS ENUM ('STREAM', 'OFFLINE');
CREATE TYPE offline_status AS ENUM ('ACTIVE', 'EXPIRED', 'DELETED_BY_USER', 'DELETED_BY_SYSTEM');
CREATE TYPE product_kind AS ENUM ('SUBJECT_TERM', 'SEMESTER_BUNDLE', 'COURSE');
CREATE TYPE payment_method AS ENUM ('SHAMCASH_API', 'SHAMCASH_QR_MANUAL', 'PRINTED_VOUCHER', 'ADMIN_GRANT');
CREATE TYPE payment_status AS ENUM ('PENDING', 'AWAITING_REVIEW', 'PAID', 'REJECTED', 'FAILED', 'CANCELLED', 'EXPIRED', 'REFUNDED');
CREATE TYPE review_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE voucher_status AS ENUM ('PRINTED', 'ACTIVATED', 'REDEEMED', 'VOIDED');
CREATE TYPE entitlement_status AS ENUM ('ACTIVE', 'REVOKED');
CREATE TYPE result_status AS ENUM ('PASSED', 'FAILED', 'CARRIED', 'ABSENT', 'PENDING');
CREATE TYPE import_status AS ENUM ('UPLOADED', 'PROCESSING', 'NEEDS_REVIEW', 'APPLIED', 'FAILED');
CREATE TYPE match_status AS ENUM ('MATCHED', 'AMBIGUOUS', 'UNMATCHED');
CREATE TYPE announcement_source AS ENUM ('UNIVERSITY_OFFICIAL', 'APP_TEAM');
CREATE TYPE notification_kind AS ENUM ('ANNOUNCEMENT', 'EXAM_REMINDER', 'RETAKE_REMINDER', 'SUBSCRIPTION_EXPIRING', 'SUBSCRIPTION_EXPIRED', 'PAYMENT_UPDATE', 'SUPPORT_REPLY', 'GRADES_RELEASED', 'SYSTEM');
CREATE TYPE audience_kind AS ENUM ('ALL', 'DEPARTMENT', 'CONTAINER_ENTITLED', 'USER');
CREATE TYPE delivery_status AS ENUM ('PENDING', 'SENT', 'FAILED');
CREATE TYPE conversation_topic AS ENUM ('GENERAL', 'DEVICE_CHANGE', 'PAYMENT', 'CONTENT_ISSUE', 'ACCOUNT', 'OTHER');
CREATE TYPE conversation_status AS ENUM ('OPEN', 'WAITING_USER', 'WAITING_SUPPORT', 'RESOLVED', 'CLOSED');


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
  updated_at timestamptz NOT NULL DEFAULT now()
);

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

CREATE TABLE student_term_enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  term_id uuid NOT NULL,
  department_id uuid NOT NULL,
  study_year smallint NOT NULL,
  status enrollment_status NOT NULL DEFAULT 'ACTIVE',
  confirmed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, term_id),
  CHECK (study_year BETWEEN 1 AND 3)
);

CREATE TABLE department_subjects (
  department_id uuid,
  subject_id uuid,
  study_year smallint NOT NULL,
  semester_in_year smallint NOT NULL,
  position smallint NOT NULL DEFAULT 0,
  is_required boolean NOT NULL DEFAULT true,
  counts_toward_progress boolean NOT NULL DEFAULT true,
  PRIMARY KEY (department_id, subject_id),
  CHECK (semester_in_year IN (1,2))
);

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
  pdf_download_policy pdf_download_policy NOT NULL DEFAULT 'DOWNLOADABLE',
  sort_order int NOT NULL DEFAULT 0,
  published_at timestamptz,
  created_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, kind)
);

CREATE TABLE subjects (
  container_id uuid PRIMARY KEY,
  kind container_kind NOT NULL DEFAULT 'SUBJECT',
  code varchar(20) NOT NULL UNIQUE,
  practical_weight smallint NOT NULL,
  theoretical_weight smallint NOT NULL,
  pass_mark smallint NOT NULL DEFAULT 60,
  credit_hours smallint,
  is_graduation_project boolean NOT NULL DEFAULT false,
  CHECK (kind = 'SUBJECT'),
  CHECK (practical_weight + theoretical_weight = 100)
);

CREATE TABLE course_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(30) NOT NULL UNIQUE,
  name_ar varchar(100) NOT NULL,
  name_en varchar(100),
  icon varchar(50),
  sort_order smallint NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE courses (
  container_id uuid PRIMARY KEY,
  kind container_kind NOT NULL DEFAULT 'COURSE',
  category_id uuid NOT NULL,
  level course_level NOT NULL DEFAULT 'BEGINNER',
  estimated_hours numeric(5,1),
  prerequisites text,
  CHECK (kind = 'COURSE')
);

CREATE TABLE course_outcomes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL,
  position smallint NOT NULL,
  text_ar varchar(255) NOT NULL,
  UNIQUE (course_id, position)
);

CREATE TABLE lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  container_id uuid NOT NULL,
  position int NOT NULL,
  title_ar varchar(200) NOT NULL,
  title_en varchar(200),
  description text,
  is_free_preview boolean NOT NULL DEFAULT false,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (container_id, position)
);

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

CREATE TABLE video_subtitles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_asset_id uuid NOT NULL,
  language_code varchar(5) NOT NULL,
  label varchar(40) NOT NULL,
  file_id uuid NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  UNIQUE (video_asset_id, language_code)
);

CREATE TABLE pdf_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar varchar(200) NOT NULL,
  description text,
  is_free boolean NOT NULL DEFAULT true,
  status publish_status NOT NULL DEFAULT 'DRAFT',
  position int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

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

CREATE TABLE container_pdfs (
  pdf_id uuid PRIMARY KEY,
  container_id uuid NOT NULL
);

CREATE TABLE lesson_pdfs (
  pdf_id uuid PRIMARY KEY,
  lesson_id uuid NOT NULL
);

CREATE TABLE content_contributors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name varchar(150) NOT NULL,
  headline varchar(150),
  user_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pdf_contributors (
  pdf_id uuid,
  contributor_id uuid,
  role contributor_role DEFAULT 'AUTHOR',
  PRIMARY KEY (pdf_id, contributor_id, role)
);


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

CREATE TABLE mcq_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id uuid NOT NULL,
  position smallint NOT NULL,
  option_text text NOT NULL,
  is_correct boolean NOT NULL DEFAULT false,
  feedback text,
  UNIQUE (exercise_id, position)
);

CREATE TABLE code_exercise_specs (
  exercise_id uuid PRIMARY KEY,
  programming_language varchar(30) NOT NULL,
  starter_code text,
  reference_solution text,
  grading_instructions text NOT NULL,
  expected_behavior text,
  max_code_length int NOT NULL DEFAULT 8000
);

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

CREATE TABLE attempt_mcq_choices (
  attempt_id uuid PRIMARY KEY,
  option_id uuid NOT NULL
);

CREATE TABLE code_submissions (
  attempt_id uuid PRIMARY KEY,
  source_code text NOT NULL,
  programming_language varchar(30) NOT NULL
);

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

CREATE TABLE ai_evaluation_findings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_id uuid NOT NULL,
  line_start int,
  line_end int,
  severity finding_severity NOT NULL DEFAULT 'ERROR',
  message text NOT NULL
);


CREATE TABLE lesson_watch_progress (
  user_id uuid,
  lesson_id uuid,
  last_position_seconds int NOT NULL DEFAULT 0,
  total_watched_seconds int NOT NULL DEFAULT 0,
  first_watched_at timestamptz NOT NULL DEFAULT now(),
  last_watched_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, lesson_id)
);

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

CREATE TABLE usage_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  started_at timestamptz NOT NULL,
  last_heartbeat_at timestamptz NOT NULL,
  ended_at timestamptz,
  active_seconds int NOT NULL DEFAULT 0,
  app_version varchar(20)
);

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
  UNIQUE (device_id, video_asset_id)
);

CREATE TABLE offline_pdf_downloads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  pdf_version_id uuid NOT NULL,
  entitlement_id uuid,
  status offline_status NOT NULL DEFAULT 'ACTIVE',
  downloaded_at timestamptz NOT NULL DEFAULT now(),
  last_verified_at timestamptz,
  removed_at timestamptz,
  UNIQUE (device_id, pdf_version_id)
);

CREATE TABLE device_time_syncs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,
  server_time timestamptz NOT NULL,
  device_time timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT now()
);


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

CREATE TABLE product_prices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL,
  amount numeric(14,2) NOT NULL,
  currency char(3) NOT NULL DEFAULT 'SYP',
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_to timestamptz,
  created_by_admin_id uuid,
  UNIQUE (product_id, currency, effective_from),
  CHECK (amount >= 0)
);

CREATE TABLE product_subject_term (
  product_id uuid PRIMARY KEY,
  kind product_kind NOT NULL DEFAULT 'SUBJECT_TERM',
  subject_id uuid NOT NULL,
  term_id uuid NOT NULL,
  UNIQUE (subject_id, term_id),
  CHECK (kind = 'SUBJECT_TERM')
);

CREATE TABLE product_semester_bundle (
  product_id uuid PRIMARY KEY,
  kind product_kind NOT NULL DEFAULT 'SEMESTER_BUNDLE',
  term_id uuid NOT NULL,
  department_id uuid NOT NULL,
  study_year smallint NOT NULL,
  UNIQUE (term_id, department_id, study_year),
  CHECK (kind = 'SEMESTER_BUNDLE')
);

CREATE TABLE product_course (
  product_id uuid PRIMARY KEY,
  kind product_kind NOT NULL DEFAULT 'COURSE',
  course_id uuid NOT NULL,
  access_duration_days int,
  CHECK (kind = 'COURSE')
);

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

CREATE TABLE payment_admin_grants (
  payment_id uuid PRIMARY KEY,
  granted_by_admin_id uuid NOT NULL,
  reason text NOT NULL
);

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

CREATE TABLE grades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  subject_id uuid NOT NULL,
  term_id uuid NOT NULL,
  session exam_session NOT NULL DEFAULT 'REGULAR',
  practical_mark numeric(5,2),
  theoretical_mark numeric(5,2),
  total_mark numeric(5,2) GENERATED ALWAYS AS (practical_mark + theoretical_mark) STORED,
  result_status result_status NOT NULL DEFAULT 'PENDING',
  released_at timestamptz,
  import_row_id uuid UNIQUE,
  transcript_submission_id uuid,
  entered_by_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, subject_id, term_id, session),
  CHECK (num_nonnulls(import_row_id, transcript_submission_id) <= 1)
);

CREATE TABLE grade_report_exports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  term_id uuid,
  file_id uuid,
  generated_at timestamptz NOT NULL DEFAULT now()
);


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

CREATE TABLE announcement_attachments (
  announcement_id uuid,
  file_id uuid,
  position smallint NOT NULL DEFAULT 0,
  caption varchar(200),
  PRIMARY KEY (announcement_id, file_id)
);

CREATE TABLE notification_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(40) NOT NULL UNIQUE,
  title_pattern varchar(200) NOT NULL,
  body_pattern text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

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

CREATE TABLE notification_recipients (
  notification_id uuid,
  user_id uuid,
  delivery_status delivery_status NOT NULL DEFAULT 'PENDING',
  delivered_at timestamptz,
  read_at timestamptz,
  error_message varchar(255),
  PRIMARY KEY (notification_id, user_id)
);

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

CREATE TABLE support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_admin_id uuid,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz
);

CREATE TABLE support_message_attachments (
  message_id uuid,
  file_id uuid,
  PRIMARY KEY (message_id, file_id)
);


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

CREATE TABLE feature_flags (
  key varchar(60) PRIMARY KEY,
  is_enabled boolean NOT NULL DEFAULT false,
  description text,
  updated_by_admin_id uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app_settings (
  key varchar(60) PRIMARY KEY,
  value jsonb NOT NULL,
  description text,
  updated_by_admin_id uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);

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


ALTER TABLE oauth_identities ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE student_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE student_profiles ADD FOREIGN KEY (entry_academic_year_id) REFERENCES academic_years(id);
ALTER TABLE user_preferences ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE devices ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE devices ADD FOREIGN KEY (authorized_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE device_change_requests ADD FOREIGN KEY (new_device_id) REFERENCES devices(id);
ALTER TABLE device_change_requests ADD FOREIGN KEY (old_device_id) REFERENCES devices(id);
ALTER TABLE device_change_requests ADD FOREIGN KEY (conversation_id) REFERENCES support_conversations(id);
ALTER TABLE device_change_requests ADD FOREIGN KEY (decided_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE auth_sessions ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE security_events ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE security_events ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE security_events ADD FOREIGN KEY (reviewed_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE terms ADD FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);
ALTER TABLE student_term_enrollments ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE student_term_enrollments ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE student_term_enrollments ADD FOREIGN KEY (department_id) REFERENCES departments(id);
ALTER TABLE department_subjects ADD FOREIGN KEY (department_id) REFERENCES departments(id);
ALTER TABLE department_subjects ADD FOREIGN KEY (subject_id) REFERENCES subjects(container_id);
ALTER TABLE exam_schedules ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE exam_schedules ADD FOREIGN KEY (subject_id) REFERENCES subjects(container_id);
ALTER TABLE exam_schedules ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE files ADD FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id);
ALTER TABLE files ADD FOREIGN KEY (uploaded_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE learning_containers ADD FOREIGN KEY (cover_file_id) REFERENCES files(id);
ALTER TABLE learning_containers ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE subjects ADD FOREIGN KEY (container_id,kind) REFERENCES learning_containers(id,kind);
ALTER TABLE courses ADD FOREIGN KEY (category_id) REFERENCES course_categories(id);
ALTER TABLE courses ADD FOREIGN KEY (container_id,kind) REFERENCES learning_containers(id,kind);
ALTER TABLE course_outcomes ADD FOREIGN KEY (course_id) REFERENCES courses(container_id);
ALTER TABLE lessons ADD FOREIGN KEY (container_id) REFERENCES learning_containers(id);
ALTER TABLE video_assets ADD FOREIGN KEY (lesson_id) REFERENCES lessons(id);
ALTER TABLE video_assets ADD FOREIGN KEY (source_file_id) REFERENCES files(id);
ALTER TABLE video_assets ADD FOREIGN KEY (thumbnail_file_id) REFERENCES files(id);
ALTER TABLE video_renditions ADD FOREIGN KEY (video_asset_id) REFERENCES video_assets(id);
ALTER TABLE video_subtitles ADD FOREIGN KEY (video_asset_id) REFERENCES video_assets(id);
ALTER TABLE video_subtitles ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE pdf_versions ADD FOREIGN KEY (pdf_id) REFERENCES pdf_documents(id);
ALTER TABLE pdf_versions ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE pdf_versions ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE container_pdfs ADD FOREIGN KEY (pdf_id) REFERENCES pdf_documents(id);
ALTER TABLE container_pdfs ADD FOREIGN KEY (container_id) REFERENCES learning_containers(id);
ALTER TABLE lesson_pdfs ADD FOREIGN KEY (pdf_id) REFERENCES pdf_documents(id);
ALTER TABLE lesson_pdfs ADD FOREIGN KEY (lesson_id) REFERENCES lessons(id);
ALTER TABLE content_contributors ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE pdf_contributors ADD FOREIGN KEY (pdf_id) REFERENCES pdf_documents(id);
ALTER TABLE pdf_contributors ADD FOREIGN KEY (contributor_id) REFERENCES content_contributors(id);
ALTER TABLE exercises ADD FOREIGN KEY (lesson_id) REFERENCES lessons(id);
ALTER TABLE mcq_options ADD FOREIGN KEY (exercise_id) REFERENCES exercises(id);
ALTER TABLE code_exercise_specs ADD FOREIGN KEY (exercise_id) REFERENCES exercises(id);
ALTER TABLE exercise_attempts ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE exercise_attempts ADD FOREIGN KEY (exercise_id) REFERENCES exercises(id);
ALTER TABLE attempt_mcq_choices ADD FOREIGN KEY (attempt_id) REFERENCES exercise_attempts(id);
ALTER TABLE attempt_mcq_choices ADD FOREIGN KEY (option_id) REFERENCES mcq_options(id);
ALTER TABLE code_submissions ADD FOREIGN KEY (attempt_id) REFERENCES exercise_attempts(id);
ALTER TABLE ai_evaluations ADD FOREIGN KEY (attempt_id) REFERENCES code_submissions(attempt_id);
ALTER TABLE ai_evaluation_findings ADD FOREIGN KEY (evaluation_id) REFERENCES ai_evaluations(id);
ALTER TABLE lesson_watch_progress ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE lesson_watch_progress ADD FOREIGN KEY (lesson_id) REFERENCES lessons(id);
ALTER TABLE lesson_ratings ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE lesson_ratings ADD FOREIGN KEY (lesson_id) REFERENCES lessons(id);
ALTER TABLE usage_sessions ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE video_license_requests ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE video_license_requests ADD FOREIGN KEY (video_asset_id) REFERENCES video_assets(id);
ALTER TABLE video_license_requests ADD FOREIGN KEY (entitlement_id) REFERENCES entitlements(id);
ALTER TABLE offline_video_downloads ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE offline_video_downloads ADD FOREIGN KEY (video_asset_id) REFERENCES video_assets(id);
ALTER TABLE offline_video_downloads ADD FOREIGN KEY (rendition_id) REFERENCES video_renditions(id);
ALTER TABLE offline_video_downloads ADD FOREIGN KEY (entitlement_id) REFERENCES entitlements(id);
ALTER TABLE offline_pdf_downloads ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE offline_pdf_downloads ADD FOREIGN KEY (pdf_version_id) REFERENCES pdf_versions(id);
ALTER TABLE offline_pdf_downloads ADD FOREIGN KEY (entitlement_id) REFERENCES entitlements(id);
ALTER TABLE device_time_syncs ADD FOREIGN KEY (device_id) REFERENCES devices(id);
ALTER TABLE product_prices ADD FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE product_prices ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE product_subject_term ADD FOREIGN KEY (subject_id) REFERENCES subjects(container_id);
ALTER TABLE product_subject_term ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE product_subject_term ADD FOREIGN KEY (product_id,kind) REFERENCES products(id,kind);
ALTER TABLE product_semester_bundle ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE product_semester_bundle ADD FOREIGN KEY (department_id) REFERENCES departments(id);
ALTER TABLE product_semester_bundle ADD FOREIGN KEY (product_id,kind) REFERENCES products(id,kind);
ALTER TABLE product_course ADD FOREIGN KEY (course_id) REFERENCES courses(container_id);
ALTER TABLE product_course ADD FOREIGN KEY (product_id,kind) REFERENCES products(id,kind);
ALTER TABLE payments ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE payments ADD FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE payments ADD FOREIGN KEY (price_id) REFERENCES product_prices(id);
ALTER TABLE payment_shamcash ADD FOREIGN KEY (payment_id) REFERENCES payments(id);
ALTER TABLE payment_manual_receipts ADD FOREIGN KEY (payment_id) REFERENCES payments(id);
ALTER TABLE payment_manual_receipts ADD FOREIGN KEY (receipt_file_id) REFERENCES files(id);
ALTER TABLE payment_manual_receipts ADD FOREIGN KEY (reviewed_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE payment_admin_grants ADD FOREIGN KEY (payment_id) REFERENCES payments(id);
ALTER TABLE payment_admin_grants ADD FOREIGN KEY (granted_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE voucher_batches ADD FOREIGN KEY (outlet_id) REFERENCES voucher_outlets(id);
ALTER TABLE voucher_batches ADD FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE voucher_batches ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE vouchers ADD FOREIGN KEY (batch_id) REFERENCES voucher_batches(id);
ALTER TABLE vouchers ADD FOREIGN KEY (redeemed_payment_id) REFERENCES payments(id);
ALTER TABLE entitlements ADD FOREIGN KEY (payment_id) REFERENCES payments(id);
ALTER TABLE entitlements ADD FOREIGN KEY (revoked_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE grade_import_batches ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE grade_import_batches ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE grade_import_batches ADD FOREIGN KEY (uploaded_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE grade_import_rows ADD FOREIGN KEY (batch_id) REFERENCES grade_import_batches(id);
ALTER TABLE grade_import_rows ADD FOREIGN KEY (subject_id) REFERENCES subjects(container_id);
ALTER TABLE grade_import_rows ADD FOREIGN KEY (matched_user_id) REFERENCES users(id);
ALTER TABLE grade_import_rows ADD FOREIGN KEY (reviewed_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE transcript_submissions ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE transcript_submissions ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE transcript_submissions ADD FOREIGN KEY (covers_through_term_id) REFERENCES terms(id);
ALTER TABLE transcript_submissions ADD FOREIGN KEY (reviewed_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE grades ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE grades ADD FOREIGN KEY (subject_id) REFERENCES subjects(container_id);
ALTER TABLE grades ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE grades ADD FOREIGN KEY (import_row_id) REFERENCES grade_import_rows(id);
ALTER TABLE grades ADD FOREIGN KEY (transcript_submission_id) REFERENCES transcript_submissions(id);
ALTER TABLE grades ADD FOREIGN KEY (entered_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE grade_report_exports ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE grade_report_exports ADD FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE grade_report_exports ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE announcements ADD FOREIGN KEY (cover_file_id) REFERENCES files(id);
ALTER TABLE announcements ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE announcement_attachments ADD FOREIGN KEY (announcement_id) REFERENCES announcements(id);
ALTER TABLE announcement_attachments ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE notifications ADD FOREIGN KEY (template_id) REFERENCES notification_templates(id);
ALTER TABLE notifications ADD FOREIGN KEY (department_id) REFERENCES departments(id);
ALTER TABLE notifications ADD FOREIGN KEY (container_id) REFERENCES learning_containers(id);
ALTER TABLE notifications ADD FOREIGN KEY (exam_schedule_id) REFERENCES exam_schedules(id);
ALTER TABLE notifications ADD FOREIGN KEY (announcement_id) REFERENCES announcements(id);
ALTER TABLE notifications ADD FOREIGN KEY (created_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE notification_recipients ADD FOREIGN KEY (notification_id) REFERENCES notifications(id);
ALTER TABLE notification_recipients ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE support_conversations ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE support_conversations ADD FOREIGN KEY (assigned_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE support_messages ADD FOREIGN KEY (conversation_id) REFERENCES support_conversations(id);
ALTER TABLE support_messages ADD FOREIGN KEY (sender_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE support_message_attachments ADD FOREIGN KEY (message_id) REFERENCES support_messages(id);
ALTER TABLE support_message_attachments ADD FOREIGN KEY (file_id) REFERENCES files(id);
ALTER TABLE admin_audit_logs ADD FOREIGN KEY (admin_id) REFERENCES admin_accounts(id);
ALTER TABLE feature_flags ADD FOREIGN KEY (updated_by_admin_id) REFERENCES admin_accounts(id);
ALTER TABLE app_settings ADD FOREIGN KEY (updated_by_admin_id) REFERENCES admin_accounts(id);


CREATE UNIQUE INDEX uq_devices_user_id_partial ON devices (user_id) WHERE status = 'ACTIVE';
CREATE UNIQUE INDEX uq_academic_years_is_current_partial ON academic_years (is_current) WHERE is_current;
CREATE UNIQUE INDEX uq_pdf_versions_pdf_id_partial ON pdf_versions (pdf_id) WHERE is_current;
CREATE INDEX ix_oauth_identities_user_id ON oauth_identities (user_id);
CREATE INDEX ix_student_profiles_entry_academic_year_id ON student_profiles (entry_academic_year_id);
CREATE INDEX ix_devices_user_id ON devices (user_id);
CREATE INDEX ix_devices_authorized_by_admin_id ON devices (authorized_by_admin_id);
CREATE INDEX ix_device_change_requests_new_device_id ON device_change_requests (new_device_id);
CREATE INDEX ix_device_change_requests_old_device_id ON device_change_requests (old_device_id);
CREATE INDEX ix_device_change_requests_conversation_id ON device_change_requests (conversation_id);
CREATE INDEX ix_device_change_requests_decided_by_admin_id ON device_change_requests (decided_by_admin_id);
CREATE INDEX ix_auth_sessions_device_id ON auth_sessions (device_id);
CREATE INDEX ix_security_events_user_id ON security_events (user_id);
CREATE INDEX ix_security_events_device_id ON security_events (device_id);
CREATE INDEX ix_security_events_reviewed_by_admin_id ON security_events (reviewed_by_admin_id);
CREATE INDEX ix_terms_academic_year_id ON terms (academic_year_id);
CREATE INDEX ix_student_term_enrollments_user_id ON student_term_enrollments (user_id);
CREATE INDEX ix_student_term_enrollments_term_id ON student_term_enrollments (term_id);
CREATE INDEX ix_student_term_enrollments_department_id ON student_term_enrollments (department_id);
CREATE INDEX ix_exam_schedules_term_id ON exam_schedules (term_id);
CREATE INDEX ix_exam_schedules_subject_id ON exam_schedules (subject_id);
CREATE INDEX ix_exam_schedules_created_by_admin_id ON exam_schedules (created_by_admin_id);
CREATE INDEX ix_files_uploaded_by_user_id ON files (uploaded_by_user_id);
CREATE INDEX ix_files_uploaded_by_admin_id ON files (uploaded_by_admin_id);
CREATE INDEX ix_learning_containers_cover_file_id ON learning_containers (cover_file_id);
CREATE INDEX ix_learning_containers_created_by_admin_id ON learning_containers (created_by_admin_id);
CREATE INDEX ix_courses_category_id ON courses (category_id);
CREATE INDEX ix_course_outcomes_course_id ON course_outcomes (course_id);
CREATE INDEX ix_lessons_container_id ON lessons (container_id);
CREATE INDEX ix_video_assets_source_file_id ON video_assets (source_file_id);
CREATE INDEX ix_video_assets_thumbnail_file_id ON video_assets (thumbnail_file_id);
CREATE INDEX ix_video_renditions_video_asset_id ON video_renditions (video_asset_id);
CREATE INDEX ix_video_subtitles_video_asset_id ON video_subtitles (video_asset_id);
CREATE INDEX ix_video_subtitles_file_id ON video_subtitles (file_id);
CREATE INDEX ix_pdf_versions_pdf_id ON pdf_versions (pdf_id);
CREATE INDEX ix_pdf_versions_file_id ON pdf_versions (file_id);
CREATE INDEX ix_pdf_versions_created_by_admin_id ON pdf_versions (created_by_admin_id);
CREATE INDEX ix_container_pdfs_container_id ON container_pdfs (container_id);
CREATE INDEX ix_lesson_pdfs_lesson_id ON lesson_pdfs (lesson_id);
CREATE INDEX ix_content_contributors_user_id ON content_contributors (user_id);
CREATE INDEX ix_exercises_lesson_id ON exercises (lesson_id);
CREATE INDEX ix_mcq_options_exercise_id ON mcq_options (exercise_id);
CREATE INDEX ix_exercise_attempts_user_id ON exercise_attempts (user_id);
CREATE INDEX ix_exercise_attempts_exercise_id ON exercise_attempts (exercise_id);
CREATE INDEX ix_attempt_mcq_choices_option_id ON attempt_mcq_choices (option_id);
CREATE INDEX ix_ai_evaluations_attempt_id ON ai_evaluations (attempt_id);
CREATE INDEX ix_ai_evaluation_findings_evaluation_id ON ai_evaluation_findings (evaluation_id);
CREATE INDEX ix_usage_sessions_device_id ON usage_sessions (device_id);
CREATE INDEX ix_video_license_requests_device_id ON video_license_requests (device_id);
CREATE INDEX ix_video_license_requests_video_asset_id ON video_license_requests (video_asset_id);
CREATE INDEX ix_video_license_requests_entitlement_id ON video_license_requests (entitlement_id);
CREATE INDEX ix_offline_video_downloads_device_id ON offline_video_downloads (device_id);
CREATE INDEX ix_offline_video_downloads_video_asset_id ON offline_video_downloads (video_asset_id);
CREATE INDEX ix_offline_video_downloads_rendition_id ON offline_video_downloads (rendition_id);
CREATE INDEX ix_offline_video_downloads_entitlement_id ON offline_video_downloads (entitlement_id);
CREATE INDEX ix_offline_pdf_downloads_device_id ON offline_pdf_downloads (device_id);
CREATE INDEX ix_offline_pdf_downloads_pdf_version_id ON offline_pdf_downloads (pdf_version_id);
CREATE INDEX ix_offline_pdf_downloads_entitlement_id ON offline_pdf_downloads (entitlement_id);
CREATE INDEX ix_device_time_syncs_device_id ON device_time_syncs (device_id);
CREATE INDEX ix_product_prices_product_id ON product_prices (product_id);
CREATE INDEX ix_product_prices_created_by_admin_id ON product_prices (created_by_admin_id);
CREATE INDEX ix_product_subject_term_subject_id ON product_subject_term (subject_id);
CREATE INDEX ix_product_subject_term_term_id ON product_subject_term (term_id);
CREATE INDEX ix_product_semester_bundle_term_id ON product_semester_bundle (term_id);
CREATE INDEX ix_product_semester_bundle_department_id ON product_semester_bundle (department_id);
CREATE INDEX ix_product_course_course_id ON product_course (course_id);
CREATE INDEX ix_payments_user_id ON payments (user_id);
CREATE INDEX ix_payments_product_id ON payments (product_id);
CREATE INDEX ix_payments_price_id ON payments (price_id);
CREATE INDEX ix_payment_manual_receipts_receipt_file_id ON payment_manual_receipts (receipt_file_id);
CREATE INDEX ix_payment_manual_receipts_reviewed_by_admin_id ON payment_manual_receipts (reviewed_by_admin_id);
CREATE INDEX ix_payment_admin_grants_granted_by_admin_id ON payment_admin_grants (granted_by_admin_id);
CREATE INDEX ix_voucher_batches_outlet_id ON voucher_batches (outlet_id);
CREATE INDEX ix_voucher_batches_product_id ON voucher_batches (product_id);
CREATE INDEX ix_voucher_batches_created_by_admin_id ON voucher_batches (created_by_admin_id);
CREATE INDEX ix_vouchers_batch_id ON vouchers (batch_id);
CREATE INDEX ix_entitlements_revoked_by_admin_id ON entitlements (revoked_by_admin_id);
CREATE INDEX ix_grade_import_batches_term_id ON grade_import_batches (term_id);
CREATE INDEX ix_grade_import_batches_file_id ON grade_import_batches (file_id);
CREATE INDEX ix_grade_import_batches_uploaded_by_admin_id ON grade_import_batches (uploaded_by_admin_id);
CREATE INDEX ix_grade_import_rows_batch_id ON grade_import_rows (batch_id);
CREATE INDEX ix_grade_import_rows_subject_id ON grade_import_rows (subject_id);
CREATE INDEX ix_grade_import_rows_matched_user_id ON grade_import_rows (matched_user_id);
CREATE INDEX ix_grade_import_rows_reviewed_by_admin_id ON grade_import_rows (reviewed_by_admin_id);
CREATE INDEX ix_transcript_submissions_user_id ON transcript_submissions (user_id);
CREATE INDEX ix_transcript_submissions_file_id ON transcript_submissions (file_id);
CREATE INDEX ix_transcript_submissions_covers_through_term_id ON transcript_submissions (covers_through_term_id);
CREATE INDEX ix_transcript_submissions_reviewed_by_admin_id ON transcript_submissions (reviewed_by_admin_id);
CREATE INDEX ix_grades_user_id ON grades (user_id);
CREATE INDEX ix_grades_subject_id ON grades (subject_id);
CREATE INDEX ix_grades_term_id ON grades (term_id);
CREATE INDEX ix_grades_transcript_submission_id ON grades (transcript_submission_id);
CREATE INDEX ix_grades_entered_by_admin_id ON grades (entered_by_admin_id);
CREATE INDEX ix_grade_report_exports_user_id ON grade_report_exports (user_id);
CREATE INDEX ix_grade_report_exports_term_id ON grade_report_exports (term_id);
CREATE INDEX ix_grade_report_exports_file_id ON grade_report_exports (file_id);
CREATE INDEX ix_announcements_cover_file_id ON announcements (cover_file_id);
CREATE INDEX ix_announcements_created_by_admin_id ON announcements (created_by_admin_id);
CREATE INDEX ix_notifications_template_id ON notifications (template_id);
CREATE INDEX ix_notifications_department_id ON notifications (department_id);
CREATE INDEX ix_notifications_container_id ON notifications (container_id);
CREATE INDEX ix_notifications_exam_schedule_id ON notifications (exam_schedule_id);
CREATE INDEX ix_notifications_announcement_id ON notifications (announcement_id);
CREATE INDEX ix_notifications_created_by_admin_id ON notifications (created_by_admin_id);
CREATE INDEX ix_support_conversations_user_id ON support_conversations (user_id);
CREATE INDEX ix_support_conversations_assigned_admin_id ON support_conversations (assigned_admin_id);
CREATE INDEX ix_support_messages_conversation_id ON support_messages (conversation_id);
CREATE INDEX ix_support_messages_sender_admin_id ON support_messages (sender_admin_id);
CREATE INDEX ix_admin_audit_logs_admin_id ON admin_audit_logs (admin_id);
CREATE INDEX ix_feature_flags_updated_by_admin_id ON feature_flags (updated_by_admin_id);
CREATE INDEX ix_app_settings_updated_by_admin_id ON app_settings (updated_by_admin_id);

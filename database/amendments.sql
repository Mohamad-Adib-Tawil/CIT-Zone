-- Local design amendments. Notion's original code is preserved separately.
-- These constraints protect data consistency; API authorization and DRM remain external.

ALTER TABLE learning_containers
  ADD COLUMN free_preview_count integer NOT NULL DEFAULT 1 CHECK (free_preview_count >= 1),
  ADD CONSTRAINT ck_container_pdf_policy CHECK (
    (kind = 'SUBJECT' AND pdf_download_policy = 'DOWNLOADABLE') OR
    (kind = 'COURSE' AND pdf_download_policy IN ('VIEW_ONLY', 'ENCRYPTED_IN_APP')));
ALTER TABLE department_subjects DROP CONSTRAINT department_subjects_pkey;
ALTER TABLE department_subjects ADD PRIMARY KEY (department_id, subject_id, study_year, semester_in_year);
ALTER TABLE department_subjects ADD CHECK (study_year IN (1, 2));
ALTER TABLE product_semester_bundle ADD CHECK (study_year IN (1, 2));
ALTER TABLE lessons ADD CHECK (position >= 1);
ALTER TABLE files ADD CHECK (size_bytes >= 0);
ALTER TABLE auth_sessions ADD CHECK (expires_at > issued_at);
ALTER TABLE entitlements ADD CHECK (ends_at IS NULL OR ends_at > starts_at);
ALTER TABLE product_course ADD COLUMN duration_mode text NOT NULL
  CHECK (duration_mode IN ('FINITE', 'LIFETIME'));
ALTER TABLE product_course ADD CHECK (
  (duration_mode = 'FINITE' AND access_duration_days IS NOT NULL AND access_duration_days > 0) OR
  (duration_mode = 'LIFETIME' AND access_duration_days IS NULL));
ALTER TABLE usage_sessions ADD CHECK (active_seconds >= 0);
ALTER TABLE usage_sessions ADD CHECK (last_heartbeat_at >= started_at);
ALTER TABLE usage_sessions ADD CHECK (ended_at IS NULL OR ended_at >= last_heartbeat_at);
ALTER TABLE lesson_watch_progress ADD CHECK (last_position_seconds >= 0 AND total_watched_seconds >= 0);
ALTER TABLE product_prices ADD UNIQUE (id, product_id);
ALTER TABLE payments ADD FOREIGN KEY (price_id, product_id) REFERENCES product_prices(id, product_id);
ALTER TABLE student_profiles ADD COLUMN legacy_transcript_eligible boolean NOT NULL DEFAULT false;
ALTER TABLE transcript_submissions ADD CHECK (
  status = 'PENDING' OR (reviewed_by_admin_id IS NOT NULL AND reviewed_at IS NOT NULL));
ALTER TABLE payment_manual_receipts ADD CHECK (
  review_status = 'PENDING' OR (reviewed_by_admin_id IS NOT NULL AND reviewed_at IS NOT NULL));

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
ALTER TABLE grades ADD COLUMN grading_scheme_id uuid NOT NULL;
ALTER TABLE grades ADD COLUMN change_reason text;
ALTER TABLE grades ADD FOREIGN KEY (grading_scheme_id, subject_id, term_id)
  REFERENCES grading_schemes(id, subject_id, term_id);
CREATE TABLE grade_revisions (
  id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  grade_id uuid NOT NULL REFERENCES grades(id),
  changed_by_admin_id uuid NOT NULL REFERENCES admin_accounts(id),
  reason text NOT NULL CHECK (length(trim(reason)) > 0),
  previous_record jsonb NOT NULL,
  new_record jsonb NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now()
);

-- Explicit bundle membership is fixed once a purchase exists (not derived from a changing curriculum).
CREATE TABLE product_bundle_subjects (
  product_id uuid NOT NULL REFERENCES product_semester_bundle(product_id),
  subject_id uuid NOT NULL REFERENCES subjects(container_id),
  PRIMARY KEY (product_id, subject_id)
);

-- This is license metadata, never an embedded decryption key.
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
ALTER TABLE offline_pdf_downloads ADD COLUMN license_id uuid REFERENCES protected_pdf_licenses(id);
ALTER TABLE offline_video_downloads ADD COLUMN license_request_id uuid NOT NULL REFERENCES video_license_requests(id);
ALTER TABLE video_license_requests ADD CHECK (
  NOT is_granted OR (expires_at IS NOT NULL AND expires_at > issued_at));

CREATE VIEW v_lesson_preview AS
SELECT l.id AS lesson_id, l.container_id, l.position,
       row_number() OVER (PARTITION BY l.container_id ORDER BY l.position, l.id)
         <= c.free_preview_count AS is_free_preview
FROM lessons l JOIN learning_containers c ON c.id = l.container_id
WHERE l.status = 'PUBLISHED' AND c.status = 'PUBLISHED';

CREATE VIEW v_pdf_content AS
SELECT p.id AS pdf_id, p.is_free, p.status, cp.container_id
FROM pdf_documents p JOIN container_pdfs cp ON cp.pdf_id = p.id
UNION ALL
SELECT p.id, p.is_free, p.status, l.container_id
FROM pdf_documents p JOIN lesson_pdfs lp ON lp.pdf_id = p.id JOIN lessons l ON l.id = lp.lesson_id;

CREATE VIEW v_entitlement_scope AS
SELECT e.id AS entitlement_id, p.user_id, st.subject_id AS container_id, e.starts_at, e.ends_at, e.status, p.status AS payment_status
FROM entitlements e JOIN payments p ON p.id = e.payment_id JOIN product_subject_term st ON st.product_id = p.product_id
UNION ALL
SELECT e.id, p.user_id, pc.course_id, e.starts_at, e.ends_at, e.status, p.status
FROM entitlements e JOIN payments p ON p.id = e.payment_id JOIN product_course pc ON pc.product_id = p.product_id
UNION ALL
SELECT e.id, p.user_id, b.subject_id, e.starts_at, e.ends_at, e.status, p.status
FROM entitlements e JOIN payments p ON p.id = e.payment_id JOIN product_bundle_subjects b ON b.product_id = p.product_id;

CREATE VIEW v_effective_access AS
SELECT s.entitlement_id, s.user_id, s.container_id, s.starts_at, s.ends_at
FROM v_entitlement_scope s
JOIN users u ON u.id = s.user_id
JOIN learning_containers c ON c.id = s.container_id
WHERE s.status = 'ACTIVE' AND s.payment_status = 'PAID' AND u.status = 'ACTIVE'
  AND c.status = 'PUBLISHED' AND s.starts_at <= now() AND (s.ends_at IS NULL OR now() < s.ends_at);

-- Course exercises are deferred. Completion here covers academic lessons only.
-- A published lesson with no exercises returns NULL: its product policy is still open.
CREATE VIEW v_lesson_completion AS
WITH activity AS (
  SELECT user_id, lesson_id FROM lesson_watch_progress
  UNION
  SELECT a.user_id, x.lesson_id FROM exercise_attempts a JOIN exercises x ON x.id = a.exercise_id
)
SELECT a.user_id, a.lesson_id, l.container_id,
       CASE WHEN count(x.id) = 0 THEN NULL ELSE bool_and(EXISTS (
         SELECT 1 FROM exercise_attempts t WHERE t.user_id = a.user_id AND t.exercise_id = x.id
           AND t.status = 'EVALUATED' AND t.is_passed IS TRUE)) END AS is_completed
FROM activity a JOIN lessons l ON l.id = a.lesson_id
JOIN learning_containers c ON c.id = l.container_id AND c.kind = 'SUBJECT'
LEFT JOIN exercises x ON x.lesson_id = l.id AND x.status = 'PUBLISHED'
WHERE l.status = 'PUBLISHED' AND c.status = 'PUBLISHED'
GROUP BY a.user_id, a.lesson_id, l.container_id;

CREATE VIEW v_container_progress AS
SELECT p.user_id, p.container_id,
       count(*) FILTER (WHERE p.is_completed IS TRUE) AS completed_lessons,
       (SELECT count(*) FROM lessons l WHERE l.container_id = p.container_id AND l.status = 'PUBLISHED') AS published_lessons
FROM v_lesson_completion p GROUP BY p.user_id, p.container_id;

-- Raw inputs only: do not invent cumulative-average, retake or week-boundary rules.
CREATE VIEW v_academic_progress_inputs AS
SELECT g.user_id, g.subject_id, g.term_id, g.session, g.total_mark, g.result_status,
       s.pass_mark, sub.credit_hours
FROM grades g JOIN grading_schemes s ON s.id = g.grading_scheme_id
JOIN subjects sub ON sub.container_id = g.subject_id WHERE g.released_at IS NOT NULL;
CREATE VIEW v_weekly_activity_inputs AS
SELECT d.user_id, u.id AS usage_session_id, u.started_at, u.last_heartbeat_at, u.ended_at, u.active_seconds
FROM usage_sessions u JOIN devices d ON d.id = u.device_id;

CREATE FUNCTION freeze_used_grading_scheme() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM grades WHERE grading_scheme_id = OLD.id) THEN
    RAISE EXCEPTION 'Referenced grading scheme is immutable; create a new version';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_freeze_grading_scheme BEFORE UPDATE OR DELETE ON grading_schemes
FOR EACH ROW EXECUTE FUNCTION freeze_used_grading_scheme();

CREATE FUNCTION validate_grade() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE s grading_schemes; r grade_import_rows; b grade_import_batches; t transcript_submissions;
BEGIN
  SELECT * INTO STRICT s FROM grading_schemes WHERE id = NEW.grading_scheme_id FOR SHARE;
  IF NEW.practical_mark < 0 OR NEW.practical_mark > s.practical_max OR
     NEW.theoretical_mark < 0 OR NEW.theoretical_mark > s.theoretical_max THEN
    RAISE EXCEPTION 'Grade component out of raw scale';
  END IF;
  IF NEW.result_status IN ('ABSENT','PENDING') THEN
    NEW.total_mark := NULL;
  ELSE
    IF NEW.theoretical_mark IS NULL OR (s.practical_weight > 0 AND NEW.practical_mark IS NULL) THEN
      RAISE EXCEPTION 'Complete marks required';
    END IF;
    NEW.total_mark := round(NEW.theoretical_mark / s.theoretical_max * s.theoretical_weight +
      CASE WHEN s.practical_weight = 0 THEN 0 ELSE NEW.practical_mark / s.practical_max * s.practical_weight END, 2);
    IF (NEW.result_status = 'PASSED' AND NEW.total_mark < s.pass_mark) OR
       (NEW.result_status IN ('FAILED','CARRIED') AND NEW.total_mark >= s.pass_mark) THEN
      RAISE EXCEPTION 'Result conflicts with subject pass mark';
    END IF;
  END IF;
  IF NEW.released_at IS NOT NULL THEN
    IF NEW.entered_by_admin_id IS NULL THEN RAISE EXCEPTION 'Administrative approval required'; END IF;
    IF NEW.import_row_id IS NOT NULL THEN
      SELECT * INTO STRICT r FROM grade_import_rows WHERE id = NEW.import_row_id;
      SELECT * INTO STRICT b FROM grade_import_batches WHERE id = r.batch_id;
      IF r.match_status <> 'MATCHED' OR r.matched_user_id IS DISTINCT FROM NEW.user_id OR
         r.subject_id IS DISTINCT FROM NEW.subject_id OR r.reviewed_by_admin_id IS NULL OR
         b.status <> 'APPLIED' OR b.term_id <> NEW.term_id OR b.session <> NEW.session THEN
        RAISE EXCEPTION 'Unreviewed or mismatched OCR row';
      END IF;
    ELSIF NEW.transcript_submission_id IS NOT NULL THEN
      SELECT * INTO STRICT t FROM transcript_submissions WHERE id = NEW.transcript_submission_id;
      IF t.user_id <> NEW.user_id OR t.status <> 'APPROVED' OR NOT EXISTS (
        SELECT 1 FROM student_profiles WHERE user_id = NEW.user_id AND legacy_transcript_eligible) THEN
        RAISE EXCEPTION 'Approved eligible legacy transcript required';
      END IF;
    END IF;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.released_at IS NOT NULL AND NEW IS DISTINCT FROM OLD THEN
    IF NEW.entered_by_admin_id IS NULL OR coalesce(length(trim(NEW.change_reason)),0) = 0 THEN
      RAISE EXCEPTION 'Published grade change needs an administrator and reason';
    END IF;
    INSERT INTO grade_revisions(grade_id,changed_by_admin_id,reason,previous_record,new_record)
      VALUES(OLD.id,NEW.entered_by_admin_id,NEW.change_reason,to_jsonb(OLD),to_jsonb(NEW));
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_validate_grade BEFORE INSERT OR UPDATE ON grades FOR EACH ROW EXECUTE FUNCTION validate_grade();

CREATE FUNCTION validate_mcq() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target uuid; x exercises;
BEGIN
  IF TG_TABLE_NAME = 'exercises' THEN target := coalesce(NEW.id, OLD.id);
  ELSE target := coalesce(NEW.exercise_id, OLD.exercise_id); END IF;
  SELECT * INTO x FROM exercises WHERE id = target FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF x.exercise_type = 'MCQ' AND x.status = 'PUBLISHED' AND NOT EXISTS (
    SELECT 1 FROM mcq_options WHERE exercise_id = target AND is_correct) THEN
    RAISE EXCEPTION 'Published MCQ requires at least one correct option';
  END IF;
  IF x.exercise_type <> 'MCQ' AND EXISTS (SELECT 1 FROM mcq_options WHERE exercise_id = target) THEN
    RAISE EXCEPTION 'Only MCQ exercises may have options';
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER tr_mcq_exercise AFTER INSERT OR UPDATE ON exercises
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_mcq();
CREATE CONSTRAINT TRIGGER tr_mcq_options AFTER INSERT OR UPDATE OR DELETE ON mcq_options
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_mcq();

CREATE FUNCTION validate_attempt_choice() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM exercise_attempts a JOIN mcq_options o ON o.exercise_id = a.exercise_id
                 JOIN exercises x ON x.id = a.exercise_id
                 WHERE a.id = NEW.attempt_id AND o.id = NEW.option_id AND x.exercise_type = 'MCQ') THEN
    RAISE EXCEPTION 'MCQ option does not belong to attempted exercise';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_attempt_choice BEFORE INSERT OR UPDATE ON attempt_mcq_choices
FOR EACH ROW EXECUTE FUNCTION validate_attempt_choice();

CREATE FUNCTION validate_payment_details() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target uuid; p payments; n integer;
BEGIN
  IF TG_TABLE_NAME = 'payments' THEN target := coalesce(NEW.id, OLD.id);
  ELSIF TG_TABLE_NAME = 'vouchers' THEN target := coalesce(NEW.redeemed_payment_id, OLD.redeemed_payment_id);
  ELSE target := coalesce(NEW.payment_id, OLD.payment_id); END IF;
  SELECT * INTO p FROM payments WHERE id = target FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT (SELECT count(*) FROM payment_shamcash WHERE payment_id = target) +
         (SELECT count(*) FROM payment_manual_receipts WHERE payment_id = target) +
         (SELECT count(*) FROM payment_admin_grants WHERE payment_id = target) +
         (SELECT count(*) FROM vouchers WHERE redeemed_payment_id = target) INTO n;
  IF (EXISTS (SELECT 1 FROM payment_shamcash WHERE payment_id = target) AND p.method <> 'SHAMCASH_API') OR
     (EXISTS (SELECT 1 FROM payment_manual_receipts WHERE payment_id = target) AND p.method <> 'SHAMCASH_QR_MANUAL') OR
     (EXISTS (SELECT 1 FROM payment_admin_grants WHERE payment_id = target) AND p.method <> 'ADMIN_GRANT') OR
     (EXISTS (SELECT 1 FROM vouchers WHERE redeemed_payment_id = target) AND p.method <> 'PRINTED_VOUCHER') OR n > 1 THEN
    RAISE EXCEPTION 'Payment detail subtype does not match method';
  END IF;
  IF p.status = 'PAID' THEN
    IF n <> 1 OR p.paid_at IS NULL THEN RAISE EXCEPTION 'Paid payment requires one verified detail and paid_at'; END IF;
    IF p.method = 'SHAMCASH_API' AND NOT EXISTS (
      SELECT 1 FROM payment_shamcash g JOIN product_prices q ON q.id = p.price_id
      WHERE g.payment_id = p.id AND g.verified_at IS NOT NULL
        AND g.reported_amount = q.amount AND g.reported_currency = q.currency) THEN
      RAISE EXCEPTION 'Gateway amount/currency must be verified';
    ELSIF p.method = 'SHAMCASH_QR_MANUAL' AND NOT EXISTS (
      SELECT 1 FROM payment_manual_receipts WHERE payment_id = p.id AND review_status = 'APPROVED') THEN
      RAISE EXCEPTION 'Manual receipt must be approved';
    ELSIF p.method = 'PRINTED_VOUCHER' AND NOT EXISTS (
      SELECT 1 FROM vouchers v JOIN voucher_batches b ON b.id = v.batch_id
      WHERE v.redeemed_payment_id = p.id AND v.status = 'REDEEMED' AND b.product_id = p.product_id) THEN
      RAISE EXCEPTION 'Voucher must redeem the same product';
    END IF;
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER tr_payment_details AFTER INSERT OR UPDATE ON payments
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_payment_details();
CREATE CONSTRAINT TRIGGER tr_shamcash_details AFTER INSERT OR UPDATE OR DELETE ON payment_shamcash
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_payment_details();
CREATE CONSTRAINT TRIGGER tr_manual_details AFTER INSERT OR UPDATE OR DELETE ON payment_manual_receipts
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_payment_details();
CREATE CONSTRAINT TRIGGER tr_grant_details AFTER INSERT OR UPDATE OR DELETE ON payment_admin_grants
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_payment_details();
CREATE CONSTRAINT TRIGGER tr_voucher_details AFTER INSERT OR UPDATE OR DELETE ON vouchers
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_payment_details();

CREATE FUNCTION freeze_purchased_bundle() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target uuid;
BEGIN
  target := coalesce(NEW.product_id,OLD.product_id);
  PERFORM 1 FROM products WHERE id = target FOR UPDATE;
  IF EXISTS (SELECT 1 FROM payments WHERE product_id = target) THEN
    RAISE EXCEPTION 'Purchased bundle membership is immutable; create another product version';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_bundle_freeze BEFORE INSERT OR UPDATE OR DELETE ON product_bundle_subjects
FOR EACH ROW EXECUTE FUNCTION freeze_purchased_bundle();

CREATE FUNCTION validate_pdf_policy() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target uuid; p pdf_documents; owners integer; k container_kind;
BEGIN
  IF TG_TABLE_NAME = 'pdf_documents' THEN target := coalesce(NEW.id,OLD.id);
  ELSE target := coalesce(NEW.pdf_id,OLD.pdf_id); END IF;
  SELECT * INTO p FROM pdf_documents WHERE id = target FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT count(*), min(c.kind::text)::container_kind INTO owners,k
    FROM v_pdf_content v JOIN learning_containers c ON c.id = v.container_id WHERE v.pdf_id = target;
  IF owners > 1 OR (p.status = 'PUBLISHED' AND owners <> 1) THEN
    RAISE EXCEPTION 'PDF must have exactly one owner before publication';
  END IF;
  IF owners = 1 AND ((k = 'SUBJECT' AND NOT p.is_free) OR (k = 'COURSE' AND p.is_free)) THEN
    RAISE EXCEPTION 'Academic PDF must be free; course PDF must be protected';
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER tr_pdf_policy AFTER INSERT OR UPDATE ON pdf_documents
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_pdf_policy();
CREATE CONSTRAINT TRIGGER tr_container_pdf_policy AFTER INSERT OR UPDATE OR DELETE ON container_pdfs
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_pdf_policy();
CREATE CONSTRAINT TRIGGER tr_lesson_pdf_policy AFTER INSERT OR UPDATE OR DELETE ON lesson_pdfs
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_pdf_policy();

CREATE FUNCTION validate_license_owner() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE cid uuid; uid uuid; grant_end timestamptz;
BEGIN
  IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'protected_pdf_licenses' AND
     (to_jsonb(NEW) - 'revoked_at') = (to_jsonb(OLD) - 'revoked_at') THEN RETURN NEW; END IF;
  IF TG_TABLE_NAME = 'video_license_requests' THEN
    IF NOT NEW.is_granted THEN RETURN NEW; END IF;
  END IF;
  IF NEW.expires_at IS NULL OR NEW.expires_at <= now() THEN
    RAISE EXCEPTION 'A new granted license requires a future server expiry';
  END IF;
  SELECT d.user_id INTO uid FROM devices d JOIN users u ON u.id = d.user_id
    WHERE d.id = NEW.device_id AND d.status = 'ACTIVE' AND u.status = 'ACTIVE';
  IF uid IS NULL THEN RAISE EXCEPTION 'License requires an active user and device'; END IF;
  IF TG_TABLE_NAME = 'video_license_requests' THEN
    SELECT l.container_id INTO cid FROM video_assets v JOIN lessons l ON l.id = v.lesson_id
      JOIN learning_containers c ON c.id = l.container_id
      WHERE v.id = NEW.video_asset_id AND v.status = 'READY' AND l.status = 'PUBLISHED' AND c.status = 'PUBLISHED';
    IF cid IS NULL THEN RAISE EXCEPTION 'Video is not playable'; END IF;
    IF NEW.entitlement_id IS NULL THEN
      IF NOT EXISTS (SELECT 1 FROM video_assets v JOIN v_lesson_preview l ON l.lesson_id = v.lesson_id
                     WHERE v.id = NEW.video_asset_id AND l.is_free_preview) THEN
        RAISE EXCEPTION 'A non-preview video requires entitlement';
      END IF;
      RETURN NEW;
    END IF;
  ELSE
    SELECT v.container_id INTO cid FROM pdf_versions pv JOIN v_pdf_content v ON v.pdf_id = pv.pdf_id
      JOIN learning_containers c ON c.id = v.container_id
      WHERE pv.id = NEW.pdf_version_id AND v.status = 'PUBLISHED' AND c.status = 'PUBLISHED'
        AND c.kind = 'COURSE' AND c.pdf_download_policy = 'ENCRYPTED_IN_APP';
    IF cid IS NULL THEN RAISE EXCEPTION 'PDF is not eligible for an offline protected license'; END IF;
  END IF;
  SELECT ends_at INTO grant_end FROM v_effective_access
    WHERE entitlement_id = NEW.entitlement_id AND user_id = uid AND container_id = cid;
  IF NOT FOUND THEN RAISE EXCEPTION 'Device and entitlement user/content mismatch or expired entitlement'; END IF;
  IF NEW.expires_at IS NULL OR NEW.expires_at <= now() OR (grant_end IS NOT NULL AND NEW.expires_at > grant_end) THEN
    RAISE EXCEPTION 'License expiry must be positive and bounded by server entitlement';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_video_license_owner BEFORE INSERT ON video_license_requests
FOR EACH ROW EXECUTE FUNCTION validate_license_owner();
CREATE TRIGGER tr_pdf_license_owner BEFORE INSERT OR UPDATE ON protected_pdf_licenses
FOR EACH ROW EXECUTE FUNCTION validate_license_owner();

CREATE FUNCTION validate_offline_download() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE c container_kind;
BEGIN
  IF TG_TABLE_NAME = 'offline_video_downloads' THEN
    IF NOT EXISTS (
      SELECT 1 FROM video_license_requests r JOIN video_renditions v ON v.video_asset_id = r.video_asset_id
      WHERE r.id = NEW.license_request_id AND r.device_id = NEW.device_id
        AND r.video_asset_id = NEW.video_asset_id AND v.id = NEW.rendition_id
        AND r.entitlement_id IS NOT DISTINCT FROM NEW.entitlement_id AND r.is_granted AND r.license_type = 'OFFLINE'
        AND (NEW.status <> 'ACTIVE' OR (r.expires_at > now() AND (r.entitlement_id IS NULL OR EXISTS (
          SELECT 1 FROM v_effective_access a WHERE a.entitlement_id = r.entitlement_id
            AND a.user_id = (SELECT user_id FROM devices WHERE id = NEW.device_id)))))) THEN
      RAISE EXCEPTION 'Download must match granted offline video license and rendition';
    END IF;
  ELSE
    SELECT lc.kind INTO c FROM pdf_versions pv JOIN v_pdf_content p ON p.pdf_id = pv.pdf_id
      JOIN learning_containers lc ON lc.id = p.container_id WHERE pv.id = NEW.pdf_version_id;
    IF c IS NULL THEN RAISE EXCEPTION 'PDF owner missing'; END IF;
    IF c = 'COURSE' AND NOT EXISTS (
      SELECT 1 FROM protected_pdf_licenses r WHERE r.id = NEW.license_id AND r.device_id = NEW.device_id
        AND r.pdf_version_id = NEW.pdf_version_id AND r.entitlement_id = NEW.entitlement_id
        AND (NEW.status <> 'ACTIVE' OR (r.revoked_at IS NULL AND r.expires_at > now() AND EXISTS (
          SELECT 1 FROM v_effective_access a WHERE a.entitlement_id = r.entitlement_id
            AND a.user_id = (SELECT user_id FROM devices WHERE id = NEW.device_id))))) THEN
      RAISE EXCEPTION 'Course PDF download requires matching protected license';
    ELSIF c = 'SUBJECT' AND (NEW.license_id IS NOT NULL OR NEW.entitlement_id IS NOT NULL) THEN
      RAISE EXCEPTION 'Free academic PDF does not depend on paid entitlement';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_video_download BEFORE INSERT OR UPDATE ON offline_video_downloads
FOR EACH ROW EXECUTE FUNCTION validate_offline_download();
CREATE TRIGGER tr_pdf_download BEFORE INSERT OR UPDATE ON offline_pdf_downloads
FOR EACH ROW EXECUTE FUNCTION validate_offline_download();

-- Prevent moving a child record to another parent without rechecking the old parent.
CREATE FUNCTION immutable_reference() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE col text;
BEGIN
  FOREACH col IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW)->col) IS DISTINCT FROM (to_jsonb(OLD)->col) THEN
      RAISE EXCEPTION 'Reference %.% is immutable',TG_TABLE_NAME,col;
    END IF;
  END LOOP;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_mcq_parent BEFORE UPDATE ON mcq_options FOR EACH ROW EXECUTE FUNCTION immutable_reference('exercise_id');
CREATE TRIGGER tr_pdf_container_parent BEFORE UPDATE ON container_pdfs FOR EACH ROW EXECUTE FUNCTION immutable_reference('pdf_id','container_id');
CREATE TRIGGER tr_pdf_lesson_parent BEFORE UPDATE ON lesson_pdfs FOR EACH ROW EXECUTE FUNCTION immutable_reference('pdf_id','lesson_id');
CREATE TRIGGER tr_lesson_parent BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION immutable_reference('container_id');
CREATE TRIGGER tr_container_kind BEFORE UPDATE ON learning_containers FOR EACH ROW EXECUTE FUNCTION immutable_reference('kind');
CREATE TRIGGER tr_device_user BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION immutable_reference('user_id');
CREATE TRIGGER tr_entitlement_parent BEFORE UPDATE ON entitlements FOR EACH ROW EXECUTE FUNCTION immutable_reference('payment_id');
CREATE TRIGGER tr_payment_identity BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION immutable_reference('user_id','product_id','price_id','method');
CREATE TRIGGER tr_shamcash_parent BEFORE UPDATE ON payment_shamcash FOR EACH ROW EXECUTE FUNCTION immutable_reference('payment_id');
CREATE TRIGGER tr_receipt_parent BEFORE UPDATE ON payment_manual_receipts FOR EACH ROW EXECUTE FUNCTION immutable_reference('payment_id');
CREATE TRIGGER tr_grant_parent BEFORE UPDATE ON payment_admin_grants FOR EACH ROW EXECUTE FUNCTION immutable_reference('payment_id');
CREATE TRIGGER tr_bundle_parent BEFORE UPDATE ON product_bundle_subjects FOR EACH ROW EXECUTE FUNCTION immutable_reference('product_id','subject_id');
CREATE TRIGGER tr_attempt_parent BEFORE UPDATE ON exercise_attempts FOR EACH ROW EXECUTE FUNCTION immutable_reference('user_id','exercise_id');
CREATE TRIGGER tr_pdf_version_parent BEFORE UPDATE ON pdf_versions FOR EACH ROW EXECUTE FUNCTION immutable_reference('pdf_id');
CREATE TRIGGER tr_pdf_version_file BEFORE UPDATE ON pdf_versions FOR EACH ROW EXECUTE FUNCTION immutable_reference('file_id','version_no');
CREATE TRIGGER tr_exercise_parent BEFORE UPDATE ON exercises FOR EACH ROW EXECUTE FUNCTION immutable_reference('lesson_id');
CREATE TRIGGER tr_ocr_parent BEFORE UPDATE ON grade_import_rows FOR EACH ROW EXECUTE FUNCTION immutable_reference('batch_id');

CREATE FUNCTION reject_historical_write() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Historical record % is append-only',TG_TABLE_NAME; END $$;
CREATE TRIGGER tr_video_license_history BEFORE UPDATE OR DELETE ON video_license_requests
FOR EACH ROW EXECUTE FUNCTION reject_historical_write();
CREATE TRIGGER tr_grade_revision_history BEFORE UPDATE OR DELETE ON grade_revisions
FOR EACH ROW EXECUTE FUNCTION reject_historical_write();

CREATE FUNCTION freeze_used_source() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE used boolean;
BEGIN
  IF TG_TABLE_NAME = 'grade_import_rows' THEN
    SELECT EXISTS (SELECT 1 FROM grades WHERE import_row_id = OLD.id AND released_at IS NOT NULL)
      OR EXISTS (SELECT 1 FROM grade_import_batches WHERE id = OLD.batch_id AND status = 'APPLIED') INTO used;
  ELSE
    SELECT EXISTS (SELECT 1 FROM grades WHERE transcript_submission_id = OLD.id AND released_at IS NOT NULL) INTO used;
  END IF;
  IF used THEN RAISE EXCEPTION 'Published grade source is immutable; publish a reviewed revision'; END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_ocr_source_history BEFORE UPDATE OR DELETE ON grade_import_rows FOR EACH ROW EXECUTE FUNCTION freeze_used_source();
CREATE TRIGGER tr_transcript_history BEFORE UPDATE OR DELETE ON transcript_submissions FOR EACH ROW EXECUTE FUNCTION freeze_used_source();

CREATE FUNCTION preserve_published_grade() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.released_at IS NOT NULL THEN RAISE EXCEPTION 'Published grade must be revised, not deleted'; END IF;
  RETURN OLD;
END $$;
CREATE TRIGGER tr_grade_delete BEFORE DELETE ON grades FOR EACH ROW EXECUTE FUNCTION preserve_published_grade();

CREATE FUNCTION validate_applied_batch() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target uuid; b grade_import_batches;
BEGIN
  IF TG_TABLE_NAME = 'grade_import_batches' THEN target := coalesce(NEW.id,OLD.id);
  ELSE target := coalesce(NEW.batch_id,OLD.batch_id); END IF;
  SELECT * INTO b FROM grade_import_batches WHERE id = target FOR UPDATE;
  IF FOUND AND b.status = 'APPLIED' AND (
    NOT EXISTS (SELECT 1 FROM grade_import_rows WHERE batch_id = target) OR
    EXISTS (SELECT 1 FROM grade_import_rows WHERE batch_id = target AND
      (match_status <> 'MATCHED' OR matched_user_id IS NULL OR subject_id IS NULL OR reviewed_by_admin_id IS NULL))) THEN
    RAISE EXCEPTION 'Applied OCR batch must have only matched, reviewed rows';
  END IF;
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER tr_applied_batch AFTER INSERT OR UPDATE ON grade_import_batches
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_applied_batch();
CREATE CONSTRAINT TRIGGER tr_applied_rows AFTER INSERT OR UPDATE OR DELETE ON grade_import_rows
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_applied_batch();

CREATE FUNCTION lock_purchase_product() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM products WHERE id = NEW.product_id FOR UPDATE;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_purchase_product_lock BEFORE INSERT ON payments FOR EACH ROW EXECUTE FUNCTION lock_purchase_product();
CREATE FUNCTION freeze_purchased_product_data() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM 1 FROM products WHERE id = OLD.product_id FOR UPDATE;
  IF EXISTS (SELECT 1 FROM payments WHERE product_id = OLD.product_id) THEN
    RAISE EXCEPTION 'Purchased product mapping/price is immutable; create a new version';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_price_history BEFORE UPDATE OR DELETE ON product_prices FOR EACH ROW EXECUTE FUNCTION freeze_purchased_product_data();
CREATE TRIGGER tr_course_product_history BEFORE UPDATE OR DELETE ON product_course FOR EACH ROW EXECUTE FUNCTION freeze_purchased_product_data();
CREATE TRIGGER tr_subject_product_history BEFORE UPDATE OR DELETE ON product_subject_term FOR EACH ROW EXECUTE FUNCTION freeze_purchased_product_data();
CREATE TRIGGER tr_bundle_product_history BEFORE UPDATE OR DELETE ON product_semester_bundle FOR EACH ROW EXECUTE FUNCTION freeze_purchased_product_data();

CREATE FUNCTION preserve_redeemed_voucher() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.redeemed_payment_id IS NOT NULL AND NEW.redeemed_payment_id IS DISTINCT FROM OLD.redeemed_payment_id THEN
    RAISE EXCEPTION 'Redeemed payment reference is immutable';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tr_voucher_redemption BEFORE UPDATE ON vouchers FOR EACH ROW EXECUTE FUNCTION preserve_redeemed_voucher();

CREATE INDEX ix_grading_scheme_subject_term ON grading_schemes(subject_id, term_id);
CREATE INDEX ix_grade_revisions_grade ON grade_revisions(grade_id, changed_at);
CREATE INDEX ix_pdf_license_device ON protected_pdf_licenses(device_id, expires_at);
CREATE INDEX ix_usage_sessions_time ON usage_sessions(device_id, started_at);
CREATE INDEX ix_attempts_passed ON exercise_attempts(user_id, exercise_id) WHERE status = 'EVALUATED' AND is_passed;

-- These views expose cross-user inputs. No client may connect with the schema owner.
-- Backend roles and per-request authorization are not defined until the server is selected.
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

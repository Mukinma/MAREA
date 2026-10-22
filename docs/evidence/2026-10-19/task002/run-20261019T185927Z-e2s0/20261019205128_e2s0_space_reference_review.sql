BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='2s';
SET LOCAL statement_timeout='30s';
-- Review correction only; preserve the original S0 implementation and receipts.
DROP TRIGGER aa_s0_reference ON public.tours;
CREATE TRIGGER aa_s0_reference BEFORE UPDATE OF document,revision_id,public_revision_id,space ON public.tours FOR EACH ROW EXECUTE FUNCTION collaboration.s0_deny_mutation();
DROP TRIGGER aa_s0_reference ON public.tour_revisions;
CREATE TRIGGER aa_s0_reference BEFORE UPDATE OF document,space ON public.tour_revisions FOR EACH ROW EXECUTE FUNCTION collaboration.s0_deny_mutation();
COMMIT;

-- Only execute after confirming these IDs were inserted by this batch.
BEGIN;
DELETE FROM source_records WHERE id='e00a4b9d-9686-515a-9313-02976792d5d4' AND entity_id='7fce2f44-dc43-5de4-b10c-66e94e40841a';
DELETE FROM vehicle_specs WHERE id='7fce2f44-dc43-5de4-b10c-66e94e40841a' AND powertrain_id='5d73717d-9a55-414f-80f0-32a57648bc31';
COMMIT;

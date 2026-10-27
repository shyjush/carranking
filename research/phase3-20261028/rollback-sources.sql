-- Execute only for IDs confirmed inserted by this batch.
BEGIN;
DELETE FROM source_records WHERE entity_type='depreciation_original_price' AND id IN ('44dcf56e-dee1-58af-bd21-a5d3ec69c92c','28febaef-458c-5064-b4b5-61075e8c1601','6eaaaa7b-ff3b-5a37-a4ad-12b5505a2ec5','f0264357-5a46-567c-9873-97814d8da0b9','d3a950d6-d3d8-5654-9b3d-369a6662779f','1f60cef0-c9f5-5450-8c3f-15b6b61920b2','84912345-48ba-53c8-91cb-3146dd07cc94','a976fb89-2027-5916-ac79-615edfe69b41','2563e506-6fee-5dc4-bfe6-506a1cd1e761');
COMMIT;

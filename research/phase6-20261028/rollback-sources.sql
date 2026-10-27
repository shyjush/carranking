BEGIN;
DELETE FROM source_records WHERE entity_type='depreciation_listing_review' AND id IN ('1cfec467-8043-5687-bb1c-5e4a100253cd','1aadcbe1-f924-5eba-bf8e-4a990b8c1b0b','4c7a32e0-6e72-5063-a028-9a0b012b3057','ac896e69-f546-552a-baa0-fd0c73509444','f3a2cf83-918c-55a1-be5a-9ac02d366ab1','c35c687b-0a9d-5913-9dce-9061545b31a3','06a69549-e86a-5e81-9989-eef56e38172e','d57dcf81-042f-598c-9739-3643aad98f5e') RETURNING id;
COMMIT;

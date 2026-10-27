BEGIN;
DELETE FROM source_records WHERE id IN ('3670feb4-ce46-5421-af70-e021339700f4','7b3ce574-8186-5e66-981c-d2087d4c95ce','5751dc73-17f7-5296-9ddc-d7137f6df060','2d89964b-bf3e-596c-a619-8ceafc4a8b9f','eba7826b-db33-5fdd-b802-abe53a9b9dce','3a42b1bc-f133-57bb-b5e6-9b831cc01404','066ff56d-30a5-5b62-854e-91d559615a29','4368204d-2914-5b70-88e0-eb22f6266914','e6d782d9-d4b0-5372-b712-37dbc1dda2b6') AND entity_type IN ('depreciation_original_price','depreciation_price_review') RETURNING id;
COMMIT;

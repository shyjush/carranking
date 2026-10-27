BEGIN;
WITH held AS (
 UPDATE public.depreciation_metrics d SET confidence='C',
 note=coalesce(d.note,'') || E'\n2026-10-27 evidence audit: held pending original MSRP source and dated exact-generation/year/powertrain/trim individual listings with duplicate verification. No matching market snapshot; stored prices, sample and observation date are preserved.'
 WHERE d.confidence IN ('A','B') AND NOT EXISTS(SELECT 1 FROM public.market_snapshots s WHERE s.generation_id=d.generation_id AND s.model_year=d.model_year AND s.as_of_date=d.as_of_date AND s.confidence IN ('A','B'))
 RETURNING id
) SELECT count(*) AS actual_downgraded FROM held;
COMMIT;

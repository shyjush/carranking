-- CarRanking official vehicle specifications: EV batch
-- Sources: Kia Korea official specification pages, checked 2026-08-31.
-- Only update the current generation of an exact manufacturer/model match.

begin;

-- Kia EV6: base Standard 2WD / 19-inch reference configuration.
insert into vehicle_specs (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, combined_efficiency)
select g.id, 4695, 1880, 1550, 2900, 5.5
from generations g
join car_models m on m.id = g.model_id
join manufacturers mf on mf.id = m.manufacturer_id
where mf.name = '기아' and m.name = 'EV6' and g.is_current = true
on conflict (generation_id) do update set
  length_mm = excluded.length_mm,
  width_mm = excluded.width_mm,
  height_mm = excluded.height_mm,
  wheelbase_mm = excluded.wheelbase_mm,
  combined_efficiency = excluded.combined_efficiency;

-- Kia EV9: base Standard 2WD / 19-inch 7-seat reference configuration.
insert into vehicle_specs (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, combined_efficiency)
select g.id, 5010, 1980, 1755, 3100, 4.2
from generations g
join car_models m on m.id = g.model_id
join manufacturers mf on mf.id = m.manufacturer_id
where mf.name = '기아' and m.name = 'EV9' and g.is_current = true
on conflict (generation_id) do update set
  length_mm = excluded.length_mm,
  width_mm = excluded.width_mm,
  height_mm = excluded.height_mm,
  wheelbase_mm = excluded.wheelbase_mm,
  combined_efficiency = excluded.combined_efficiency;

commit;

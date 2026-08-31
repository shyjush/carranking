begin;

-- Verified official specification batch 5.
-- Only current generations are targeted. Variant-dependent height is preserved in notes.

do $$
declare
  v_generation_id uuid;
  v_spec_id uuid;
begin
  select g.id into v_generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers m on m.id = cm.manufacturer_id
  where m.name = 'Kia' and cm.name = 'Carnival' and g.current = true
  order by g.start_year desc nulls last
  limit 1;

  if v_generation_id is not null then
    select id into v_spec_id from public.vehicle_specs
    where generation_id = v_generation_id and powertrain_id is null
    order by created_at asc limit 1;

    if v_spec_id is null then
      insert into public.vehicle_specs
        (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, source_url, verified_at)
      values
        (v_generation_id, 5155, 1995, 1775, 3090,
         'https://www.kia.com/kr/vehicles/carnival/specification', current_date)
      returning id into v_spec_id;
    else
      update public.vehicle_specs
      set length_mm = 5155,
          width_mm = 1995,
          height_mm = 1775,
          wheelbase_mm = 3090,
          source_url = 'https://www.kia.com/kr/vehicles/carnival/specification',
          verified_at = current_date
      where id = v_spec_id;
    end if;

    if not exists (
      select 1 from public.source_records
      where entity_type = 'vehicle_spec'
        and entity_id = v_spec_id
        and source_url = 'https://www.kia.com/kr/vehicles/carnival/specification'
    ) then
      insert into public.source_records
        (entity_type, entity_id, source_url, confidence, verified_at, note)
      values
        ('vehicle_spec', v_spec_id,
         'https://www.kia.com/kr/vehicles/carnival/specification',
         'A', current_date,
         'Kia official specification. 3.5 gasoline: 5155/1995/1775/3090 mm. Hybrid height is 1785 mm; high-roof derivatives are 2045-2055 mm and are not flattened into the base generation value.');
    end if;
  end if;
end $$;

commit;

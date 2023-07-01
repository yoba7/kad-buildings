select dropTable(NULL,'t04_agdp_parcels',1);

create table t04_agdp_parcels as
select parcels.*,
       case
       when buildings.ms_countOf_buildings>0 then 1
                                             else 0
       end                                              as fl_parcel_with_building,
       coalesce(buildings.ms_countOf_buildings,0)       as ms_countOf_buildings,
       coalesce(buildings.ms_area_buildings_total,0)    as ms_area_buildings_total
from t02_agdp_parcels parcels
  LEFT JOIN (
              select capakey, 
                     max(fl_building_within_parcel)               as fl_building_within_parcel,
                     count(*)                                     as ms_countOf_buildings,
                     sum(ms_area_building)                        as ms_area_buildings_total,
                     max(ms_area_building)                        as ms_area_buildings_largest
              from t03_agdp_buildings2parcels
              group by 1
            ) as buildings on parcels.capakey=buildings.capakey;

create unique index  i04_agdp_parcels     on t04_agdp_parcels(capakey     );


select dropTable(NULL,'t03_agdp_buildings2parcels',1);

create table t03_agdp_buildings2parcels as
select *,
       rank() OVER ( partition by id_building order by ms_distance_building2parcelExteriorRing ) as rk_distance_building2parcelExteriorRing
from (
        select distinct  buildings.id_building                                             as id_building,
                         parcels.capakey                                                   as capakey,
                         st_within(buildings.geometry,parcels.geometry)                    as fl_building_within_parcel,
                         st_distance(buildings.geometry,st_exteriorRing(parcels.geometry)) as ms_distance_building2parcelExteriorRing,
                         st_area(buildings.geometry)                                       as ms_area_building
        from t02_agdp_parcels as parcels, t02_agdp_buildings as buildings
        where st_within(buildings.pointOnSurface,parcels.geometry) 
          and buildings.rowid in ( 
                                   select rowid
                                   from spatialIndex
                                   where f_table_name='t02_agdp_buildings' and f_geometry_column='pointonsurface'
                                     and search_frame=parcels.geometry
                                 )
     );

create unique index i03_agdp_buildings2parcels  on t03_agdp_buildings2parcels(id_building,capakey);
create index i03_agdp_buildings2parcels_capakey on t03_agdp_buildings2parcels(capakey);
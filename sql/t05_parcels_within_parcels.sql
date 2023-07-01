drop table if exists t05_parcels_within_parcels;

create table t05_parcels_within_parcels as 
SELECT container.capakey                      as capakey_container, 
       content.capakey                        as capakey_content, 
       sum(content.ms_area_buildings_total)   as ms_area_buildings_total
from t04_agdp_parcels container, t04_agdp_parcels content
where st_within(content.geometry,st_makePolygon(st_exteriorRing(container.geometry)))
  and content.rowid in ( select distinct rowid
                         from spatialIndex
                         where f_table_name='t04_agdp_parcels' and f_geometry_column='geometry'
                               and search_frame=container.geometry )
  and substr(content.capakey,1,13)=substr(container.capakey,1,13)
  and substr(content.capakey,15,3)=substr(container.capakey,15,3)
  and container.capakey!=content.capakey
group by 1, 2;

create unique index i05_parcels_within_parcels on t05_parcels_within_parcels(capakey_container,capakey_content);


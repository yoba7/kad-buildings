insert into t06_parcels_connections(capakey_a, capakey_b, fl_intersects, geometry, ms_distance)
select distinct capakey_1                                 as capakey_a       ,
                capakey_2                                 as capakey_b       ,
                fl_intersects                             as fl_intersects   ,
                makeline(pointOnSurfaceA,pointOnSurfaceB) as geometry        ,
                ms_distance                               as ms_distance
from (
        select a.capakey                          as capakey_1       ,
               b.capakey                          as capakey_2       ,
               st_distance(a.geometry,b.geometry) as ms_distance     ,
               intersects(a.geometry,b.geometry)  as fl_intersects   ,
               a.pointOnSurface                   as pointOnSurfaceA ,
               b.pointOnSurface                   as pointOnSurfaceB
        from (
               select *
               from t04_agdp_parcels 
               where capakey in ({parcels})
              ) a, 
             t04_agdp_parcels b
        where  b.rowid in ( 
                            select distinct rowid
                            from SpatialIndex
                            where f_table_name = 't04_agdp_parcels' and f_geometry_column='geometry'
                            and search_frame = st_expand(a.geometry, {distance}+1)
                           )
               and  st_distance(a.geometry,b.geometry)<{distance}
               and  b.ms_area_buildings_total>50 
      );

update t04_agdp_parcels
set fl_parcel_with_building=1, 
    ms_area_buildings_total  =ms_area_buildings_total+(select sum(ms_area_buildings_total) from t05_parcels_within_parcels where capakey_container=t04_agdp_parcels.capakey)
where capakey in ( select capakey_container from t05_parcels_within_parcels );
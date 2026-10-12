import {test} from 'node:test';
import assert from 'node:assert/strict';
const path='./geocoding.ts';
let api; try {api=await import(path)} catch {api={normalizePlace:()=>null}}
test('structured city does not come from street or county',()=>{
 const place=api.normalizePlace({display_name:'Calle Uno, Centro, Puebla',lat:'19',lon:'-98',address:{road:'Calle Uno',county:'Puebla County',city:'Puebla',state:'Puebla',country:'México',country_code:'mx'}});
 assert.deepEqual(place?.city,{name:'Puebla',region:'Puebla',country:'México',countryCode:'mx'});
 assert.equal(place?.label,'Calle Uno, Centro, Puebla');
});
test('no settlement yields an unknown city and preserves full address',()=>{
 const place=api.normalizePlace({display_name:'Camino Rural',lat:'21',lon:'-100',address:{road:'Camino Rural',county:'County'}});
 assert.equal(place?.city,null);
 assert.equal(place?.label,'Camino Rural');
});
test('invalid coordinates cannot become selectable search results',()=>{
 assert.equal(api.normalizePlace({display_name:'Bad',lat:'NaN',lon:'-100',address:{city:'Bad'}}),null);
});

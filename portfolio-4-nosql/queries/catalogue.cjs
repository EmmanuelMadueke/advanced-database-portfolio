// Owner, author, maintainer: Emmanuel Madueke
// Query definitions only: executed by mongosh, with no writes to profiles.
const projection={_id:1,'sql_context.name':1,profile_type:1,attributes:1,tags:1};
const active={'sql_context.is_active':true};
const material=(name='cotton',minimum=90)=>({...active,profile_type:'clothing',
 'attributes.composition':{$elemMatch:{material:name,percent:{$gte:minimum}}}});
const footwear=(fastening='lace-up')=>({...active,profile_type:'footwear','attributes.fastening':fastening});
const accessory=(minimumWidth=30)=>({...active,profile_type:'accessory',
 'attributes.features':'inner pocket','attributes.dimensions_cm.width':{$gte:minimumWidth}});
const tagged=(tag='everyday')=>({...active,tags:tag});
const tagSummary=[{$match:active},{$unwind:'$tags'},
 {$group:{_id:'$tags',profile_count:{$sum:1}}},
 {$project:{_id:0,tag:'$_id',profile_count:1}},{$sort:{profile_count:-1,tag:1}}];
module.exports={projection,material,footwear,accessory,tagged,tagSummary,
 lookup:id=>({_id:id,...active}),
 indexName:'profile_composition_lookup',
 indexKeys:{profile_type:1,'attributes.composition.material':1,'attributes.composition.percent':1}};

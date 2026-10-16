// Owner, author, maintainer: Emmanuel Madueke
// Explicitly remove only the optional experiment index when preparing a repeat.
if (!/^fashion_profiles(?:_[a-z0-9_]+)?$/.test(db.getName())) throw new Error('dedicated database required');
printjson(db.product_profiles.dropIndex('profile_composition_lookup'));

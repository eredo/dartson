part of test_builder;

void _buildEntityMap() {
  if (ENTITY_MAP == null) {
    ENTITY_MAP = {};
  }
  
  EntityDescription dsPp0 = new EntityDescription();
  dsPp0.properties = {
    "name": new EntityPropertyDescription("name",String,false)
,    "child": new EntityPropertyDescription("child",TestClass,false)
,    "boolean": new EntityPropertyDescription("boolean",bool,false)
,    "number": new EntityPropertyDescription("number",num,false)
  };
  ENTITY_MAP[reflectClass(TestClass)] = dsPp0;
}
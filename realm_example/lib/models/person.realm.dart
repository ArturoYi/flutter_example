// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Person extends _Person with RealmEntity, RealmObjectBase, RealmObject {
  Person(
    String id,
    String name,
    int age, {
    String? email,
    Address? addresses,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'age', age);
    RealmObjectBase.set(this, 'email', email);
    RealmObjectBase.set(this, 'addresses', addresses);
  }

  Person._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  int get age => RealmObjectBase.get<int>(this, 'age') as int;
  @override
  set age(int value) => RealmObjectBase.set(this, 'age', value);

  @override
  String? get email => RealmObjectBase.get<String>(this, 'email') as String?;
  @override
  set email(String? value) => RealmObjectBase.set(this, 'email', value);

  @override
  Address? get addresses =>
      RealmObjectBase.get<Address>(this, 'addresses') as Address?;
  @override
  set addresses(covariant Address? value) =>
      RealmObjectBase.set(this, 'addresses', value);

  @override
  Stream<RealmObjectChanges<Person>> get changes =>
      RealmObjectBase.getChanges<Person>(this);

  @override
  Stream<RealmObjectChanges<Person>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Person>(this, keyPaths);

  @override
  Person freeze() => RealmObjectBase.freezeObject<Person>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'age': age.toEJson(),
      'email': email.toEJson(),
      'addresses': addresses.toEJson(),
    };
  }

  static EJsonValue _toEJson(Person value) => value.toEJson();
  static Person _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'name': EJsonValue name,
        'age': EJsonValue age,
      } =>
        Person(
          fromEJson(id),
          fromEJson(name),
          fromEJson(age),
          email: fromEJson(ejson['email']),
          addresses: fromEJson(ejson['addresses']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Person._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Person, 'Person', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('age', RealmPropertyType.int),
      SchemaProperty('email', RealmPropertyType.string, optional: true),
      SchemaProperty('addresses', RealmPropertyType.object,
          optional: true, linkTarget: 'Address'),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class Address extends _Address with RealmEntity, RealmObjectBase, RealmObject {
  Address(
    String id,
    String street,
    String city,
    String country, {
    String? postalCode,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'street', street);
    RealmObjectBase.set(this, 'city', city);
    RealmObjectBase.set(this, 'country', country);
    RealmObjectBase.set(this, 'postalCode', postalCode);
  }

  Address._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get street => RealmObjectBase.get<String>(this, 'street') as String;
  @override
  set street(String value) => RealmObjectBase.set(this, 'street', value);

  @override
  String get city => RealmObjectBase.get<String>(this, 'city') as String;
  @override
  set city(String value) => RealmObjectBase.set(this, 'city', value);

  @override
  String get country => RealmObjectBase.get<String>(this, 'country') as String;
  @override
  set country(String value) => RealmObjectBase.set(this, 'country', value);

  @override
  String? get postalCode =>
      RealmObjectBase.get<String>(this, 'postalCode') as String?;
  @override
  set postalCode(String? value) =>
      RealmObjectBase.set(this, 'postalCode', value);

  @override
  Stream<RealmObjectChanges<Address>> get changes =>
      RealmObjectBase.getChanges<Address>(this);

  @override
  Stream<RealmObjectChanges<Address>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Address>(this, keyPaths);

  @override
  Address freeze() => RealmObjectBase.freezeObject<Address>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'street': street.toEJson(),
      'city': city.toEJson(),
      'country': country.toEJson(),
      'postalCode': postalCode.toEJson(),
    };
  }

  static EJsonValue _toEJson(Address value) => value.toEJson();
  static Address _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'street': EJsonValue street,
        'city': EJsonValue city,
        'country': EJsonValue country,
      } =>
        Address(
          fromEJson(id),
          fromEJson(street),
          fromEJson(city),
          fromEJson(country),
          postalCode: fromEJson(ejson['postalCode']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Address._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Address, 'Address', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('street', RealmPropertyType.string),
      SchemaProperty('city', RealmPropertyType.string),
      SchemaProperty('country', RealmPropertyType.string),
      SchemaProperty('postalCode', RealmPropertyType.string, optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

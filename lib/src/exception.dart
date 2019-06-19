import 'package:sqflite/sqlite_api.dart';

class DataException extends DatabaseException {
  final String message;
  DataException(this.message) : super(message);
}
class Bapiret {
  String type;
  String id;
  String number;
  String message; 
  String log_no; 
  String log_msg_no;
  String message_v1;
  String message_v2;
  String message_v3;
  String message_v4;
  String parameter;
  int row;
  String field; 
  String system; 

  Bapiret({this.type, this.id, this.number, this.message, this.log_no, this.log_msg_no, 
           this.message_v1, this.message_v2, this.message_v3, this.message_v4, 
           this.parameter, this.row, this.field, this.system});

  factory Bapiret.fromJson(Map<String, dynamic> json) {
    return new Bapiret(
      type: json['type'] as String,
      id: json['id'] as String,
      number: json['number'] as String,
      message: json['message'] as String,
      log_no: json['log_no'] as String,
      log_msg_no: json['log_msg_no'] as String,
      message_v1: json['message_v1'] as String,
      message_v2: json['message_v2'] as String,
      message_v3: json['message_v3'] as String,
      message_v4: json['message_v4'] as String,
      parameter: json['parameter'] as String,
      row: json['row'] as int,
      field: json['field'] as String,
      system: json['system'] as String,
    );
  }

}
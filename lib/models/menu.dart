class Menu {
  final String page;
  final String title;
  final String mtype;
  final String icon;
  final String action;

  Menu({this.page, this.title, this.mtype, this.icon, this.action});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return new Menu(
      page: json['page'] as String,
      title: json['title'] as String,
      mtype: json['mtype'] as String,
      icon: json['icon'] as String,
      action: json['action'] as String,
    );
  }
}
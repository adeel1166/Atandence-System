class Student {
  final String name;
  final DateTime amArrival;
  final DateTime amDeparture;
  final DateTime pmArrival;
  final DateTime pmDeparture;
  final int undertimeHours;
  final int undertimeMinutes;

  Student({
    required this.name,
    required this.amArrival,
    required this.amDeparture,
    required this.pmArrival,
    required this.pmDeparture,
    required this.undertimeHours,
    required this.undertimeMinutes,
  });
}

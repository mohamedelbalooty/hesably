import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

enum ReportPeriod { thisWeek, thisMonth, custom }

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReport extends ReportsEvent {
  final String businessId;
  final ReportPeriod period;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const LoadReport({
    required this.businessId,
    this.period = ReportPeriod.thisMonth,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [businessId, period, customStartDate, customEndDate];
}

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final ReportSummary summary;
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  const ReportsLoaded({
    required this.summary,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [summary, period, startDate, endDate];
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportRepository _reportRepository;

  ReportsBloc({required ReportRepository reportRepository})
      : _reportRepository = reportRepository,
        super(ReportsInitial()) {
    on<LoadReport>(_onLoadReport);
  }

  Future<void> _onLoadReport(LoadReport event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      DateTime start;
      DateTime end;
      final now = DateTime.now();

      switch (event.period) {
        case ReportPeriod.thisWeek:
          start = now.subtract(Duration(days: now.weekday - 1));
          end = start.add(const Duration(days: 6));
          break;
        case ReportPeriod.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0);
          break;
        case ReportPeriod.custom:
          start = event.customStartDate ?? now;
          end = event.customEndDate ?? now;
          break;
      }

      final summary = await _reportRepository.getReportSummary(
        businessId: event.businessId,
        startDate: start,
        endDate: end,
        includePreviousPeriod: true,
      );

      emit(ReportsLoaded(
        summary: summary,
        period: event.period,
        startDate: start,
        endDate: end,
      ));
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }
}

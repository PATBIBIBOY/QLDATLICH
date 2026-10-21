import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_session.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/customer_support/chat_list_screen.dart';
import '../screens/customer_support/support_home_screen.dart';
import '../screens/customer_support/ticket_screen.dart';
import '../screens/doctor_assistant/assistant_home_screen.dart';
import '../screens/doctor_assistant/patient_queue_screen.dart';
import '../screens/doctor_assistant/update_record_screen.dart';
import '../screens/hospital/homeHospital_Screem.dart';
import '../screens/hospital/addKhoaHospital_Screen.dart';
import '../screens/hospital/guiYeuCauHopTac_Screen.dart';
import '../screens/hospital/guiDonThanhCong_Screen.dart';
import '../screens/hospital/statistics_screen.dart';
import '../screens/hospital/staff_management_screen.dart';
import '../screens/patient/book_appointment_screen.dart';
import '../screens/patient/medical_history_screen.dart';
import '../screens/patient/my_appointments_screen.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/receptionist/appointment_list_screen.dart';
import '../screens/receptionist/check_in_screen.dart';
import '../screens/receptionist/receptionist_home_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String hospitalRegister = '/hospital-register';
  static const String roleSelection = '/role-selection';
  static const String emailVerification = '/email-verification'; // ✅ Route mới
  static const String forgotPassword = '/forgot-password';

  static const String patientHome = '/patient-home';
  static const String bookAppointment = '/book-appointment';
  static const String myAppointments = '/my-appointments';
  static const String medicalHistory = '/medical-history';

  static const String receptionistHome = '/receptionist-home';
  static const String checkIn = '/check-in';
  static const String appointmentList = '/appointment-list';

  static const String assistantHome = '/assistant-home';
  static const String patientQueue = '/patient-queue';
  static const String updateRecord = '/update-record';

  static const String supportHome = '/support-home';
  static const String chatList = '/chat-list';
  static const String ticket = '/ticket';

  static const String hospitalDashboard = '/hospital-dashboard';
  static const String hospitalRequestCollaboration =
      '/hospital-request-collaboration';
  static const String hospitalRequestSuccess = '/hospital-request-success';
  static const String addClinic = '/add-clinic';
  static const String staffManagement = '/staff-management';
  static const String nhanSuScreen = '/hospital-nhan-su';
  // ignore: constant_identifier_names
  static const String NhanSuScreen = nhanSuScreen;
  static const String statistics = '/statistics';

  static const String adminDashboard = '/admin-dashboard';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),

    // ✅ Cấu hình route nhận arguments (email)
    emailVerification: (context) {
      final email =
          ModalRoute.of(context)?.settings.arguments as String? ??
          'Email không xác định';
      return EmailVerificationScreen(email: email);
    },
    forgotPassword: (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String?;
      return ForgotPasswordScreen(initialEmail: email);
    },

    patientHome: (_) => const PatientHomeScreen(),
    bookAppointment: (_) => const BookAppointmentScreen(),
    myAppointments: (_) => const MyAppointmentsScreen(),
    medicalHistory: (_) => const MedicalHistoryScreen(),
    receptionistHome: (_) => const ReceptionistHomeScreen(),
    checkIn: (_) => const CheckInScreen(),
    appointmentList: (_) => const AppointmentListScreen(),
    assistantHome: (_) => const AssistantHomeScreen(),
    patientQueue: (_) => const PatientQueueScreen(),
    updateRecord: (_) => const UpdateRecordScreen(),
    supportHome: (_) => const SupportHomeScreen(),
    chatList: (_) => const ChatListScreen(),
    ticket: (_) => const TicketScreen(),
    hospitalDashboard: (context) {
      final tabIndex =
          ModalRoute.of(context)?.settings.arguments as int? ?? 0;
      return HomeHospitalScreen(initialTabIndex: tabIndex);
    },
    hospitalRequestCollaboration: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return GuiYeuCauHopTacScreen(
        initialTenBenhVien: args?['tenBenhVien'],
        initialDiaChi: args?['diaChi'],
      );
    },
    hospitalRequestSuccess: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return GuiDonThanhCongScreen(
        maHoSo: args?['maHoSo'] ?? '#HS-BV-202688',
        tenBenhVien: args?['tenBenhVien'] ?? 'Bệnh viện Đa Khoa An Bình',
        loaiHinh: args?['loaiHinh'] ?? 'Bệnh viện Tư lập',
        coBhyt: args?['coBhyt'] ?? true,
        extraData: args?['extraData'],
      );
    },
    addClinic: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      final bvid = (args != null && args.isNotEmpty && args != 'dFmZHBjFNUT1eRzJjXp5')
          ? args
          : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);
      return ThemKhoaScreen(benhVienId: bvid);
    },
    staffManagement: (_) => const StaffManagementScreen(),
    nhanSuScreen: (_) => const HomeHospitalScreen(initialTabIndex: 2),
    statistics: (_) => const StatisticsScreen(),
    adminDashboard: (_) => const AdminDashboard(),
  };
}

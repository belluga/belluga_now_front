import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/attribute/attribute_model.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/tenant/screens/profile/controller/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/attribute_field_list.dart';
import 'package:belluga_now/presentation/tenant/widgets/back_button_belluga.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
// import 'package:lottie/lottie.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileScreenController _controller =
      GetIt.I.get<ProfileScreenController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.zero,
        // ),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.normal,
            fontSize: 20,
            color: Color(0xff000000),
          ),
        ),
        leading: const BackButtonBelluga(),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.exit_to_app)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamValueBuilder<UserContract>(
          streamValue: _controller.userStreamValue,
          onNullWidget: const SizedBox.shrink(),
          builder: (context, user) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.network(
                          "https://cdn.pixabay.com/photo/2020/05/17/20/21/cat-5183427_960_720.jpg",
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(0),
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xff3a57e8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera,
                          color: Color(0xffffffff),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AttributeFieldList(
                    list: [
                      AttributeModel<FullNameValue?>(
                        label: "Nome",
                        value: user.profile.nameValue,
                        icons: Icons.photo_camera,
                        hint: "Qual seu nome?",
                        isEditable: true,
                      ),
                      AttributeModel<FullNameValue?>(
                        label: "Nome",
                        value: user.profile.nameValue,
                        icons: Icons.photo_camera,
                        hint: "Qual seu nome?",
                        isEditable: true,
                      ),
                      AttributeModel<FullNameValue?>(
                        label: "Nome",
                        value: user.profile.nameValue,
                        icons: Icons.photo_camera,
                        hint: "Qual seu nome?",
                        isEditable: true,
                      ),
                      AttributeModel<FullNameValue?>(
                        label: "Nome",
                        value: user.profile.nameValue,
                        icons: Icons.photo_camera,
                        hint: "Qual seu nome?",
                        isEditable: true,
                      ),
                      AttributeModel<FullNameValue?>(
                        label: "Nome",
                        value: user.profile.nameValue,
                        icons: Icons.photo_camera,
                        hint: "Qual seu nome?",
                        isEditable: true,
                      ),
                      AttributeModel<FullNameValue?>(
                        label: "Nome",
                        value: user.profile.nameValue,
                        icons: Icons.photo_camera,
                        hint: "Qual seu nome?",
                        isEditable: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _controller.logout();
    _navigateToHome();
  }

  void _navigateToHome() {
    context.router.popUntilRoot();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

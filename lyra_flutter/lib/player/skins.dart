// 播放器皮肤（占位，完整实现见后续提交）。
import 'package:flutter/material.dart';
import '../core/state.dart';
import '../ui/cover.dart';
import 'player.dart';

class SkinHost extends StatelessWidget {
  final String skin;
  const SkinHost({super.key, required this.skin});
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Column(children: [
      const PlayerTopBar(),
      const Spacer(),
      Cover.song(app.song, size: 300, radius: 22, shadow: true),
      const Spacer(),
      const SongInfo(),
      const SizedBox(height: 14),
      const ProgressBar(),
      const SizedBox(height: 10),
      const MainControls(),
      const SizedBox(height: 14),
      const AuxRow(),
      const SizedBox(height: 10),
    ]);
  }
}

class SkinThumb extends StatelessWidget {
  final String id;
  const SkinThumb(this.id, {super.key});
  @override
  Widget build(BuildContext context) => Cover.song(context.app.song, size: 0, radius: 0);
}

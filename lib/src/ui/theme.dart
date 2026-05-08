import 'package:flutter/material.dart';

/// 视觉风格：暮光珊瑚 × 文艺奶白
///
/// 设计基调融合小红书的温柔珊瑚红与文艺米白底，强调圆润卡片、柔和阴影和呼吸感留白。
class WorkbenchPalette {
  WorkbenchPalette._();

  static const Color coral = Color(0xFFE94B5C);
  static const Color coralSoft = Color(0xFFFF8A8F);
  static const Color coralWash = Color(0xFFFFE7E5);
  static const Color coralInk = Color(0xFFB23341);

  static const Color cream = Color(0xFFFBF7F1);
  static const Color creamDeep = Color(0xFFF3ECDF);
  static const Color paper = Color(0xFFFFFFFF);

  static const Color sand = Color(0xFFEDE5D8);
  static const Color sandLine = Color(0xFFE3DACB);

  static const Color inkPrimary = Color(0xFF2A2421);
  static const Color inkSecondary = Color(0xFF8C857C);
  static const Color inkSoft = Color(0xFFB8AFA4);

  static const Color matcha = Color(0xFFB8C4A6);
  static const Color honey = Color(0xFFF4C36A);
  static const Color lilac = Color(0xFFD7C7E2);
  static const Color sky = Color(0xFFA8C7D8);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFFE3DD),
      Color(0xFFFFF1E1),
      Color(0xFFF6EAD8),
    ],
    stops: <double>[0.0, 0.55, 1.0],
  );

  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFF7E83), Color(0xFFE94B5C)],
  );

  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE8EFDE), Color(0xFFD3DEC3)],
  );

  static List<BoxShadow> softShadow = const <BoxShadow>[
    BoxShadow(
      color: Color(0x14322820),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> tinyShadow = const <BoxShadow>[
    BoxShadow(
      color: Color(0x0F2A2421),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}

/// 圆润、奶油底的内容卡片。默认含柔阴影、白色背景与 18 圆角。
class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.background,
    this.border,
    this.radius = 22,
    this.gradient,
    this.shadow,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final Color? border;
  final double radius;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final radiusGeom = BorderRadius.circular(radius);
    final decoration = BoxDecoration(
      color: gradient == null ? (background ?? WorkbenchPalette.paper) : null,
      gradient: gradient,
      borderRadius: radiusGeom,
      border: Border.all(color: border ?? WorkbenchPalette.sand, width: 1),
      boxShadow: shadow ?? WorkbenchPalette.tinyShadow,
    );

    final paddedChild = Padding(padding: padding, child: child);

    return Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radiusGeom),
        child: onTap == null
            ? paddedChild
            : InkWell(
                borderRadius: radiusGeom,
                onTap: onTap,
                splashColor: WorkbenchPalette.coralWash.withValues(alpha: 0.45),
                highlightColor: WorkbenchPalette.coralWash.withValues(
                  alpha: 0.25,
                ),
                child: paddedChild,
              ),
      ),
    );
  }
}

/// 顶部 hero 渐变区域：用于首页、导入、权限页。
///
/// 内部会自动叠加状态栏高度，并把彩色装饰圆球贴到屏幕真实边缘。
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.gradient = WorkbenchPalette.heroGradient,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 14, 20, 28),
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final Gradient gradient;

  /// 内容相对 hero 边的内边距。Top 会自动叠加状态栏高度。
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final effectivePadding = EdgeInsets.fromLTRB(
      contentPadding.left,
      contentPadding.top + topInset,
      contentPadding.right,
      contentPadding.bottom,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            right: -36,
            top: -34,
            child: _DecorBlob(
              color: WorkbenchPalette.coral.withValues(alpha: 0.22),
              size: 150,
            ),
          ),
          Positioned(
            right: -18,
            bottom: -42,
            child: _DecorBlob(
              color: WorkbenchPalette.honey.withValues(alpha: 0.36),
              size: 110,
            ),
          ),
          Positioned(
            left: -34,
            bottom: 22,
            child: _DecorBlob(
              color: WorkbenchPalette.matcha.withValues(alpha: 0.32),
              size: 78,
            ),
          ),
          Padding(
            padding: effectivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: WorkbenchPalette.paper.withValues(
                                alpha: 0.78,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: WorkbenchPalette.coral.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              eyebrow,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.4,
                                color: WorkbenchPalette.coralInk,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: 0.4,
                              color: WorkbenchPalette.inkPrimary,
                            ),
                          ),
                          if (subtitle != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.6,
                                letterSpacing: 0.2,
                                color: WorkbenchPalette.inkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...<Widget>[
                      const SizedBox(width: 14),
                      trailing!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 浮在 Hero 左上角的圆形返回按钮，搭配奶白半透明背景。
class FloatingBackButton extends StatelessWidget {
  const FloatingBackButton({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WorkbenchPalette.paper.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: WorkbenchPalette.coral.withValues(alpha: 0.18),
            ),
            boxShadow: WorkbenchPalette.tinyShadow,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: WorkbenchPalette.inkPrimary,
          ),
        ),
      ),
    );
  }
}

class _DecorBlob extends StatelessWidget {
  const _DecorBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

/// 小标签：用于权限、状态等。
class SoftTag extends StatelessWidget {
  const SoftTag({
    required this.label,
    this.icon,
    this.color = WorkbenchPalette.coral,
    this.background,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? color.withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 圆形大图标贴纸：用于应用 / 示例的视觉锚点，模拟小红书贴纸感。
class IconSticker extends StatelessWidget {
  const IconSticker({
    required this.label,
    this.size = 56,
    this.gradient = WorkbenchPalette.coralGradient,
    this.textColor = Colors.white,
    super.key,
  });

  final String label;
  final double size;
  final Gradient gradient;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33E94B5C),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 点缀点（小红书常见的圆点装饰）。
class DotDecor extends StatelessWidget {
  const DotDecor({
    this.color = WorkbenchPalette.coral,
    this.size = 6,
    super.key,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

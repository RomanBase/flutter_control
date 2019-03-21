import 'core.dart';

void main() => runApp(MainSample());

class MainSample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseApp(
      title: "Flutter Control",
      root: MainSampleController(),
    );
  }
}

class MainSampleController extends BaseController {
  @override
  Widget initWidget() => MainSamplePage(this);
}

class MainSamplePage extends BasePage<MainSampleController> {
  MainSamplePage(MainSampleController controller) : super(controller: controller);

  @override
  Widget buildPage(BuildContext context, MainSampleController controller) {
    return Container();
  }
}

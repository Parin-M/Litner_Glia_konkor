import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/native_models.dart';
import '../services/native_store.dart';

const bg=Color(0xFF0B0F1A),surface=Color(0xFF171E2E),surface2=Color(0xFF1D2740),gold=Color(0xFFE8A94C),gold2=Color(0xFFF4C777),teal=Color(0xFF4FBDBA),teal2=Color(0xFF78D9D6),rose=Color(0xFFE8674F),dim=Color(0xFF8B93A7);
class NativeShell extends StatefulWidget{const NativeShell({super.key});@override State<NativeShell> createState()=>_NativeShellState();}
class _NativeShellState extends State<NativeShell>{NativeData?data;GliaStore?store;Object?error;@override void initState(){super.initState();load();}Future<void>load()async{try{final d=NativeData.fromJson(await rootBundle.loadString('assets/generated_original_deck.json'),await rootBundle.loadString('assets/generated_persian_pack.json'));final s=GliaStore(d);await s.init();if(mounted)setState((){data=d;store=s;});}catch(e){if(mounted)setState(()=>error=e);}}@override Widget build(BuildContext c){if(error!=null)return MaterialApp(home:Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline,size:60,color:rose),Text('$error'),FilledButton(onPressed:load,child:const Text('تلاش دوباره'))]))));if(data==null||store==null)return const MaterialApp(home:Scaffold(body:Center(child:CircularProgressIndicator())));return AnimatedBuilder(animation:store!,builder:(context,child){
  final dark=store!.settings.dark;
  final cs=ColorScheme.fromSeed(seedColor:dark?gold:const Color(0xFF8A5A12),brightness:dark?Brightness.dark:Brightness.light).copyWith(
    primary:dark?gold2:const Color(0xFF8A5A12),
    onPrimary:dark?const Color(0xFF1A1207):Colors.white,
    secondary:dark?teal2:const Color(0xFF176B69),
    onSecondary:dark?const Color(0xFF061515):Colors.white,
    surface:dark?surface:const Color(0xFFFFFCF5),
    onSurface:dark?Colors.white:const Color(0xFF1C1B18),
    surfaceContainerHighest:dark?surface2:const Color(0xFFEAE4D8),
    onSurfaceVariant:dark?const Color(0xFFD2D6E0):const Color(0xFF4B4A45),
    outline:dark?const Color(0xFF596276):const Color(0xFF77736A),
  );
  final text=dark?Colors.white:const Color(0xFF202124);
  final muted=dark?const Color(0xFFB8C0D0):const Color(0xFF5F5C55);
  return MaterialApp(
    debugShowCheckedModeBanner:false,title:'گلیا کنکور',
    theme:ThemeData(
      useMaterial3:true,brightness:dark?Brightness.dark:Brightness.light,
      scaffoldBackgroundColor:dark?bg:const Color(0xFFF6F2E8),colorScheme:cs,
      cardTheme:CardThemeData(color:dark?surface:Colors.white,surfaceTintColor:Colors.transparent,margin:const EdgeInsets.symmetric(vertical:4)),
      appBarTheme:AppBarTheme(backgroundColor:dark?bg:const Color(0xFFF6F2E8),foregroundColor:text,surfaceTintColor:Colors.transparent),
      drawerTheme:DrawerThemeData(backgroundColor:dark?surface:Colors.white),
      navigationBarTheme:NavigationBarThemeData(backgroundColor:dark?surface:Colors.white,indicatorColor:dark?surface2:const Color(0xFFE8D5AE),labelTextStyle:WidgetStatePropertyAll(TextStyle(color:dark?Colors.white:const Color(0xFF302F2B),fontWeight:FontWeight.w700))),
      listTileTheme:ListTileThemeData(textColor:text,subtitleTextStyle:TextStyle(color:muted),iconColor:dark?teal2:const Color(0xFF176B69)),
      inputDecorationTheme:InputDecorationTheme(labelStyle:TextStyle(color:muted),hintStyle:TextStyle(color:muted)),
      textTheme:ThemeData(brightness:dark?Brightness.dark:Brightness.light).textTheme.apply(bodyColor:text,displayColor:text),
    ),
    home:Directionality(textDirection:TextDirection.rtl,child:Home(data:data!,store:store!)),
  );
});}}
class Logo extends StatelessWidget{const Logo({super.key,this.size=52});final double size;@override Widget build(BuildContext c)=>ClipRRect(borderRadius:BorderRadius.circular(size*.2),child:Image.asset('assets/glia_icon.png',width:size,height:size,fit:BoxFit.cover,errorBuilder:(context,error,stackTrace)=>Container(width:size,height:size,color:gold,child:const Icon(Icons.psychology,color:Colors.white))));}
class Home extends StatefulWidget{const Home({super.key,required this.data,required this.store});final NativeData data;final GliaStore store;@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int tab=0;void open(String t,List<LeitnerCard>x)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonPicker(title:t,cards:x,store:widget.store)));Widget nav(String t,IconData i,VoidCallback f)=>ListTile(leading:Icon(i),title:Text(t),onTap:f);@override Widget build(BuildContext c)=>Scaffold(drawer:Drawer(child:SafeArea(child:ListView(children:[const SizedBox(height:10),const ListTile(leading:Logo(size:52),title:Text('گلیا کنکور',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:teal2)),subtitle:Text('لایتنر هوشمند',style:TextStyle(color:dim))),const Divider(),nav('خانه',Icons.home,()=>setState(()=>tab=0)),nav('دسته‌ها',Icons.grid_view,()=>setState(()=>tab=1)),nav('آمار',Icons.insights,()=>setState(()=>tab=2)),nav('تنظیمات حرفه‌ای',Icons.settings,()=>setState(()=>tab=3)),nav('یادگرفته‌ها',Icons.check_circle,(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>Status(data:widget.data,store:widget.store,known:true)));}),nav('نیازمند مرور',Icons.timelapse,(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>Status(data:widget.data,store:widget.store,known:false)));}),const Divider(),nav('کانال گلیا کنکور',Icons.telegram,()=>launchUrl(Uri.parse('https://t.me/Glia_konkor'),mode:LaunchMode.externalApplication))]))),body:IndexedStack(index:tab,children:[Dashboard(data:widget.data,store:widget.store,open:open),Categories(data:widget.data,store:widget.store,open:open),Stats(data:widget.data,store:widget.store),Settings(data:widget.data,store:widget.store)]),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.home),label:'خانه'),NavigationDestination(icon:Icon(Icons.grid_view),label:'دسته‌ها'),NavigationDestination(icon:Icon(Icons.insights),label:'آمار'),NavigationDestination(icon:Icon(Icons.settings),label:'تنظیمات')]));}
class Dashboard extends StatelessWidget{const Dashboard({super.key,required this.data,required this.store,required this.open});final NativeData data;final GliaStore store;final void Function(String,List<LeitnerCard>)open;@override Widget build(BuildContext c){final all=data.allCards,k=all.where((x)=>store.cardState[x.id]=='known').length,p=all.isEmpty?0.0:k/all.length;return ListView(padding:const EdgeInsets.all(16),children:[Row(children:[const Logo(size:58),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('گلیا کنکور',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:teal2)),Text('باهوش یاد بگیر، با اعتماد پیش برو',style:TextStyle(color:dim))]))]),const SizedBox(height:14),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(colors:[Color(0xFF152C45),Color(0xFF0D1727)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('هر روز یک قدم قوی‌تر',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:gold2)),const SizedBox(height:8),const Text('سریع، سبک و کاملاً آفلاین با Flutter.',style:TextStyle(color:dim)),const SizedBox(height:16),Row(children:[SizedBox(width:80,height:80,child:CircularProgressIndicator(value:p,color:teal,strokeWidth:8)),const SizedBox(width:14),Expanded(child:Text('پیشرفت کلی: ${(p*100).round()}٪\n${store.reviewed} مرور · ${store.correct} پاسخ درست'))]),const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>open('مرور همه کارت‌ها',List.of(all)),icon:const Icon(Icons.play_arrow),label:const Text('شروع مرور')))])) ,const SizedBox(height:12),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,children:[_cat('انگلیسی','${data.cards.where((x)=>x.category=='english').length}',teal,Icons.translate,()=>open('انگلیسی',data.cards.where((x)=>x.category=='english').toList())),_cat('افعال بی‌قاعده','${data.cards.where((x)=>x.category=='verbs').length}',const Color(0xFFA66CFF),Icons.sync_alt,()=>open('افعال بی‌قاعده',data.cards.where((x)=>x.category=='verbs').toList())),_cat('فارسی','${data.cards.where((x)=>x.category=='persian').length}',const Color(0xFF37D6A0),Icons.menu_book,()=>open('فارسی',data.cards.where((x)=>x.category=='persian').toList())),_cat('عربی','${data.cards.where((x)=>x.category=='arabic').length}',teal2,Icons.language,()=>open('عربی',data.cards.where((x)=>x.category=='arabic').toList())),_cat('پک فارسی','${data.persianPack.length}',gold2,Icons.auto_stories,()=>open('پک فارسی',data.persianPack)),_cat('املا و آزمون','${data.spelling.length}',rose,Icons.quiz,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>QuizPicker(data:data,store:store))))])]);}Widget _cat(String t,String n,Color co,IconData i,VoidCallback f)=>InkWell(onTap:f,child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:co,size:28),const Spacer(),Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),Text(n,style:const TextStyle(color:dim))])));}
class Categories extends StatelessWidget{const Categories({super.key,required this.data,required this.store,required this.open});final NativeData data;final GliaStore store;final void Function(String,List<LeitnerCard>)open;@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('همه دسته‌ها',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),for(final e in <Map<String,dynamic>>[{'t':'انگلیسی','cat':'english','i':Icons.translate,'c':teal},{'t':'افعال بی‌قاعده','cat':'verbs','i':Icons.sync_alt,'c':const Color(0xFFA66CFF)},{'t':'فارسی','cat':'persian','i':Icons.menu_book,'c':const Color(0xFF37D6A0)},{'t':'عربی','cat':'arabic','i':Icons.language,'c':teal2}])Card(child:ListTile(leading:Icon(e['i'] as IconData,color:e['c'] as Color),title:Text(e['t'] as String),subtitle:Text('${data.cards.where((x)=>x.category==e['cat']).length} کارت'),onTap:()=>open(e['t'] as String,data.cards.where((x)=>x.category==e['cat']).toList()))),Card(child:ListTile(leading:const Icon(Icons.auto_stories,color:gold2),title:const Text('پک فارسی'),subtitle:Text('${data.persianPack.length} کارت'),onTap:()=>open('پک فارسی',data.persianPack))),Card(child:ListTile(leading:const Icon(Icons.quiz,color:rose),title:const Text('املا و آزمون'),subtitle:Text('${data.spelling.length} سؤال'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>QuizPicker(data:data,store:store)))))]);}
class Stats extends StatelessWidget{const Stats({super.key,required this.data,required this.store});final NativeData data;final GliaStore store;@override Widget build(BuildContext c){final all=data.allCards,k=all.where((x)=>store.cardState[x.id]=='known').length,a=store.reviewed==0?0:(store.correct/store.reviewed*100).round();return ListView(padding:const EdgeInsets.all(16),children:[const Text('آمار عملکرد',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),Card(child:ListTile(title:const Text('مرور'),trailing:Text('${store.reviewed}'))),Card(child:ListTile(title:const Text('دقت'),trailing:Text('$a٪'))),Card(child:ListTile(title:const Text('استریک'),trailing:Text('${store.streak} روز'))),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('پیشرفت لایتنر'),const SizedBox(height:8),Text('$k از ${all.length} کارت یاد گرفته شده'),const SizedBox(height:8),LinearProgressIndicator(value:all.isEmpty?0:k/all.length,color:teal)]))) ]);}}

class LessonPicker extends StatefulWidget {
  const LessonPicker({super.key, required this.title, required this.cards, required this.store});
  final String title;
  final List<LeitnerCard> cards;
  final GliaStore store;

  @override
  State<LessonPicker> createState() => _LessonPickerState();
}

class _LessonPickerState extends State<LessonPicker> {
  String selectedLesson = 'همه درس‌ها';
  String search = '';
  bool dueOnly = true;

  List<String> get lessons {
    final values = widget.cards.map((x) => x.lesson.trim()).where((x) => x.isNotEmpty).toSet().toList();
    values.sort((a, b) => a.compareTo(b));
    return ['همه درس‌ها', ...values];
  }

  List<LeitnerCard> get filtered {
    final q = search.trim().toLowerCase();
    return widget.cards.where((card) {
      final lessonOk = selectedLesson == 'همه درس‌ها' || card.lesson == selectedLesson;
      final dueOk = !dueOnly || widget.store.isDue(card.id);
      final searchOk = q.isEmpty ||
          card.lesson.toLowerCase().contains(q) ||
          card.front.toLowerCase().contains(q) ||
          card.back.toLowerCase().contains(q);
      return lessonOk && dueOk && searchOk;
    }).toList();
  }

  void start() {
    final xs = filtered;
    if (xs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای این فیلتر کارتی پیدا نشد.')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Study(title: selectedLesson, cards: xs, store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xs = filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب درس و فیلتر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'جست‌وجوی درس یا کارت',
                  hintText: 'مثلاً Lesson 1',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: dueOnly,
              onChanged: (v) => setState(() => dueOnly = v),
              secondary: const Icon(Icons.schedule),
              title: const Text('فقط کارت‌های موعددار'),
              subtitle: Text(dueOnly ? 'کارت‌های آماده مرور' : 'همه کارت‌های انتخاب‌شده'),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: DropdownButtonFormField<String>(
                initialValue: selectedLesson,
                decoration: const InputDecoration(
                  labelText: 'درس',
                  border: InputBorder.none,
                ),
                items: lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
                onChanged: (v) => setState(() => selectedLesson = v ?? 'همه درس‌ها'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.filter_alt, color: teal2),
              title: Text('${xs.length} کارت آماده است'),
              subtitle: Text(selectedLesson == 'همه درس‌ها' ? 'همه درس‌ها' : selectedLesson),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: xs.isEmpty ? null : start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('شروع مطالعه'),
          ),
        ],
      ),
    );
  }
}

class QuizPicker extends StatefulWidget {
  const QuizPicker({super.key, required this.data, required this.store});
  final NativeData data;
  final GliaStore store;

  @override
  State<QuizPicker> createState() => _QuizPickerState();
}

class _QuizPickerState extends State<QuizPicker> {
  String selectedLesson = 'همه درس‌ها';
  String search = '';
  bool unansweredOnly = false;
  bool shuffle = true;

  List<String> get lessons {
    final values = widget.data.spelling.map((x) => x.lesson.trim()).where((x) => x.isNotEmpty).toSet().toList();
    values.sort((a, b) => a.compareTo(b));
    return ['همه درس‌ها', ...values];
  }

  List<SpellingQuestion> get filtered {
    final q = search.trim().toLowerCase();
    return widget.data.spelling.where((question) {
      final lessonOk = selectedLesson == 'همه درس‌ها' || question.lesson == selectedLesson;
      final answered = widget.store.answerLog.containsKey(question.id);
      final answerOk = !unansweredOnly || !answered;
      final searchOk = q.isEmpty ||
          question.lesson.toLowerCase().contains(q) ||
          question.sentence.toLowerCase().contains(q);
      return lessonOk && answerOk && searchOk;
    }).toList();
  }

  void start() {
    final xs = filtered;
    if (xs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای این فیلتر سؤالی پیدا نشد.')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Quiz(data: widget.data, store: widget.store, questions: xs, shuffle: shuffle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xs = filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب درس آزمون')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'جست‌وجوی درس یا سؤال',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ),
          Card(
            child: DropdownButtonFormField<String>(
              initialValue: selectedLesson,
              decoration: const InputDecoration(
                labelText: 'درس آزمون',
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
              items: lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
              onChanged: (v) => setState(() => selectedLesson = v ?? 'همه درس‌ها'),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: unansweredOnly,
              onChanged: (v) => setState(() => unansweredOnly = v),
              secondary: const Icon(Icons.pending_actions),
              title: const Text('فقط سؤال‌های حل‌نشده'),
              subtitle: Text(unansweredOnly ? 'پاسخ‌داده‌شده‌ها حذف می‌شوند' : 'همه سؤال‌های این درس'),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: shuffle,
              onChanged: (v) => setState(() => shuffle = v),
              secondary: const Icon(Icons.shuffle),
              title: const Text('ترتیب تصادفی'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.quiz, color: rose),
              title: Text('${xs.length} سؤال آماده است'),
              subtitle: Text(selectedLesson),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: xs.isEmpty ? null : start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('شروع آزمون'),
          ),
        ],
      ),
    );
  }
}

class Study extends StatefulWidget {
  const Study({super.key, required this.title, required this.cards, required this.store});
  final String title;
  final List<LeitnerCard> cards;
  final GliaStore store;

  @override
  State<Study> createState() => _StudyState();
}

class _StudyState extends State<Study> {
  late List<LeitnerCard> deck;
  int index = 0;
  bool flip = false;

  @override
  void initState() {
    super.initState();
    deck = List.of(widget.cards)
      ..removeWhere((x) => !widget.store.isDue(x.id));
    if (widget.store.settings.shuffle) deck.shuffle();
  }

  Future<void> rate(CardResult result) async {
    if (deck.isEmpty) return;
    final card = deck[index];
    await widget.store.rateCard(card, result);
    deck.removeAt(index);
    if (result == CardResult.review) deck.add(card);
    if (deck.isNotEmpty) index %= deck.length;
    setState(() => flip = false);
    if (widget.store.settings.haptics) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (deck.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 70, color: gold2),
              const Text('همه کارت‌ها بررسی شدند 🎉'),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      );
    }

    final card = deck[index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${index + 1} / ${deck.length}',
            style: const TextStyle(color: dim),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (index + 1) / deck.length,
            color: gold2,
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => setState(() => flip = !flip),
            child: AnimatedContainer(
              duration: Duration(
                milliseconds: widget.store.settings.motion ? 280 : 1,
              ),
              constraints: const BoxConstraints(minHeight: 310),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF152C45), Color(0xFF0D1727)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.lesson, style: const TextStyle(color: teal2)),
                  const Spacer(),
                  Text(
                    flip ? card.back : card.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: flip ? 23 : 32,
                      fontWeight: FontWeight.w900,
                      color: flip ? Colors.white : gold2,
                      height: 1.7,
                    ),
                  ),
                  if (flip && card.extra.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      card.extra,
                      style: const TextStyle(color: teal2),
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'لمس کن تا برگردد',
                    style: TextStyle(color: dim),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _action('دوباره', rose, () => rate(CardResult.review)),
              const SizedBox(width: 6),
              _action('بعداً', gold2, () => rate(CardResult.later)),
              const SizedBox(width: 6),
              _action(
                'یاد گرفتم',
                const Color(0xFF37D6A0),
                () => rate(CardResult.known),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String title, Color color, VoidCallback onPressed) {
    return Expanded(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: .14),
          foregroundColor: color,
        ),
        child: Text(title),
      ),
    );
  }
}

class Quiz extends StatefulWidget{const Quiz({super.key,required this.data,required this.store,required this.questions,this.shuffle=true});final NativeData data;final GliaStore store;final List<SpellingQuestion> questions;final bool shuffle;@override State<Quiz> createState()=>_QuizState();}
class _QuizState extends State<Quiz>{
  late List<SpellingQuestion> q;
  int i=0;
  int? sel;
  bool sent=false;

  @override
  void initState(){super.initState();q=List.of(widget.questions);}

  Future<void> answer(int n) async {
    if(sent)return;
    final ok=n==q[i].correctIndex;
    setState((){sel=n;sent=true;});
    await widget.store.answer(q[i],ok);
    if(widget.store.settings.haptics) HapticFeedback.selectionClick();
  }

  void next(){
    if(i+1>=q.length){Navigator.pop(context);return;}
    setState((){i++;sel=null;sent=false;});
  }

  @override
  Widget build(BuildContext c){
    final x=q[i];
    final ok=sent&&sel==x.correctIndex;
    return Scaffold(
      appBar:AppBar(title:const Text('املا و آزمون')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          LinearProgressIndicator(value:(i+1)/q.length,color:gold2),
          const SizedBox(height:14),
          Text('${i+1} / ${q.length}',style:Theme.of(c).textTheme.bodySmall),
          const SizedBox(height:8),
          Card(child:Padding(
            padding:const EdgeInsets.all(18),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(x.lesson,style:const TextStyle(color:teal2,fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              Text(x.sentence,style:const TextStyle(fontSize:21,height:2,fontWeight:FontWeight.w700)),
            ]),
          )),
          const SizedBox(height:10),
          for(int j=0;j<x.options.length;j++)
            Padding(
              padding:const EdgeInsets.only(bottom:8),
              child:FilledButton(
                onPressed:sent?null:()=>answer(j),
                style:FilledButton.styleFrom(
                  minimumSize:const Size.fromHeight(55),
                  backgroundColor:!sent?surface:(j==x.correctIndex?teal:(j==sel?rose:surface)),
                  foregroundColor:Colors.white,
                ),
                child:Align(alignment:Alignment.centerRight,child:Text(x.options[j])),
              ),
            ),
          if(sent) Card(
            color:ok?teal.withValues(alpha:.14):rose.withValues(alpha:.14),
            child:Padding(
              padding:const EdgeInsets.all(16),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Icon(ok?Icons.check_circle:Icons.cancel,color:ok?teal:rose),
                const SizedBox(width:10),
                Expanded(child:Text(
                  ok?'درست گفتی! پاسخ صحیح همین گزینه است.':'اشتباه بود. پاسخ صحیح: ${x.options[x.correctIndex]}',
                  style:TextStyle(fontWeight:FontWeight.w800,color:ok?teal:rose),
                )),
              ]),
            ),
          ),
          if(sent) const SizedBox(height:8),
          if(sent) FilledButton.icon(
            onPressed:next,
            icon:const Icon(Icons.arrow_forward),
            label:Text(i+1==q.length?'پایان آزمون':'سؤال بعدی'),
          ),
        ],
      ),
    );
  }
}
class Status extends StatelessWidget{const Status({super.key,required this.data,required this.store,required this.known});final NativeData data;final GliaStore store;final bool known;@override Widget build(BuildContext c){final xs=data.allCards.where((x)=>known?store.cardState[x.id]=='known':store.cardState[x.id]=='review'||store.cardState[x.id]=='later').toList();return Scaffold(appBar:AppBar(title:Text(known?'یادگرفته‌ها':'نیازمند مرور')),body:ListView.builder(itemCount:xs.length,itemBuilder:(_,i)=>ListTile(title:Text(xs[i].front),subtitle:Text(xs[i].back))));}}
class Settings extends StatefulWidget{const Settings({super.key,required this.data,required this.store});final NativeData data;final GliaStore store;@override State<Settings> createState()=>_SettingsState();}
class _SettingsState extends State<Settings>{Future<void>backup()async{final raw=const JsonEncoder.withIndent('  ').convert(widget.store.backup());await SharePlus.instance.share(ShareParams(files:[XFile.fromData(utf8.encode(raw),mimeType:'application/json',name:'glia-backup.json')],text:'پشتیبان گلیا کنکور'));}Future<void>restore()async{final r=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['json'],withData:true);if(r==null)return;final bytes=r.files.single.bytes;if(bytes==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('خواندن فایل پشتیبان در این پلتفرم ممکن نیست.')));return;}final raw=utf8.decode(bytes);await widget.store.restore(Map<String,dynamic>.from(jsonDecode(raw)));}Future<void>reset()async{await widget.store.resetProgress();}Future<void>setS(GliaSettings s)=>widget.store.updateSettings(s);@override Widget build(BuildContext c){final s=widget.store.settings;return ListView(padding:const EdgeInsets.all(16),children:[const Text('تنظیمات حرفه‌ای',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('ظاهر، سرعت، تعامل و پشتیبان‌گیری؛ کاملاً آفلاین.',style:TextStyle(color:dim)),_sw('حالت تاریک',s.dark,(v)=>setS(s.copyWith(dark:v)),Icons.dark_mode),_sw('انیمیشن‌ها',s.motion,(v)=>setS(s.copyWith(motion:v)),Icons.animation),_sw('بازخورد لمسی',s.haptics,(v)=>setS(s.copyWith(haptics:v)),Icons.vibration),_sw('Shuffle',s.shuffle,(v)=>setS(s.copyWith(shuffle:v)),Icons.shuffle),_sw('حالت کم‌مصرف',s.lowPower,(v)=>setS(s.copyWith(lowPower:v)),Icons.battery_saver),_sl('مکث کارت',s.delay.toDouble(),1000,8000,14,(v)=>setS(s.copyWith(delay:v.round()))),_sl('اندازه متن',s.fontScale,.9,1.2,6,(v)=>setS(s.copyWith(fontScale:v))),_sl('هدف روزانه',s.dailyGoal.toDouble(),10,100,18,(v)=>setS(s.copyWith(dailyGoal:v.round()))),Card(child:Column(children:[ListTile(leading:const Icon(Icons.ios_share,color:teal),title:const Text('پشتیبان‌گیری'),onTap:backup),ListTile(leading:const Icon(Icons.restore,color:gold2),title:const Text('بازیابی'),onTap:restore),ListTile(leading:const Icon(Icons.delete_sweep,color:rose),title:const Text('ریست کامل'),onTap:reset)])),const Card(child:ListTile(title:Text('Native / Offline'),subtitle:Text('۲۱۵۱ کارت · ۶۳۹ سؤال · ۴۳۴ کارت پک فارسی'))),const Card(child:ListTile(title:Text('ABI انتشار'),subtitle:Text('armeabi-v7a · arm64-v8a · x86_64')))]);}Widget _sw(String t,bool v,ValueChanged<bool>f,IconData i)=>Card(child:SwitchListTile(value:v,onChanged:f,secondary:Icon(i),title:Text(t)));Widget _sl(String t,double v,double a,double b,int d,ValueChanged<double>f)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[Text(t),Slider(value:v.clamp(a,b),min:a,max:b,divisions:d,onChanged:f)])));}

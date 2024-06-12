import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paginated_text/paginated_text.dart';

/// From: “The Promise of World Peace”
/// https://www.bahai.org/documents/the-universal-house-of-justice/promise-world-peace
const String pwp = '''
To the Peoples of the World:

The Great Peace towards which people of good will throughout the centuries have inclined their hearts, of which seers and poets for countless generations have expressed their vision, and for which from age to age the sacred scriptures of mankind have constantly held the promise, is now at long last within the reach of the nations. For the first time in history it is possible for everyone to view the entire planet, with all its myriad diversified peoples, in one perspective. World peace is not only possible but inevitable. It is the next stage in the evolution of this planet—in the words of one great thinker, “the planetization of mankind”.

Whether peace is to be reached only after unimaginable horrors precipitated by humanity’s stubborn clinging to old patterns of behaviour, or is to be embraced now by an act of consultative will, is the choice before all who inhabit the earth. At this critical juncture when the intractable problems confronting nations have been fused into one common concern for the whole world, failure to stem the tide of conflict and disorder would be unconscionably irresponsible.

Among the favourable signs are the steadily growing strength of the steps towards world order taken initially near the beginning of this century in the creation of the League of Nations, succeeded by the more broadly based United Nations Organization; the achievement since the Second World War of independence by the majority of all the nations on earth, indicating the completion of the process of nation building, and the involvement of these fledgling nations with older ones in matters of mutual concern; the consequent vast increase in co-operation among hitherto isolated and antagonistic peoples and groups in international undertakings in the scientific, educational, legal, economic and cultural fields; the rise in recent decades of an unprecedented number of international humanitarian organizations; the spread of women’s and youth movements calling for an end to war; and the spontaneous spawning of widening networks of ordinary people seeking understanding through personal communication.

The scientific and technological advances occurring in this unusually blessed century portend a great surge forward in the social evolution of the planet, and indicate the means by which the practical problems of humanity may be solved. They provide, indeed, the very means for the administration of the complex life of a united world. Yet barriers persist. Doubts, misconceptions, prejudices, suspicions and narrow self-interest beset nations and peoples in their relations one to another.

It is out of a deep sense of spiritual and moral duty that we are impelled at this opportune moment to invite your attention to the penetrating insights first communicated to the rulers of mankind more than a century ago by Bahá’u’lláh, Founder of the Bahá’í Faith, of which we are the Trustees.

“_The winds of despair_”, Bahá’u’lláh wrote, “_are, alas, blowing from every direction, and the strife that divides and afflicts the human race is daily increasing. The signs of impending convulsions and chaos can now be discerned, inasmuch as the prevailing order appears to be lamentably defective._” This prophetic judgement has been amply confirmed by the common experience of humanity. Flaws in the prevailing order are conspicuous in the inability of sovereign states organized as United Nations to exorcize the spectre of war, the threatened collapse of the international economic order, the spread of anarchy and terrorism, and the intense suffering which these and other afflictions are causing to increasing millions. Indeed, so much have aggression and conflict come to characterize our social, economic and religious systems, that many have succumbed to the view that such behaviour is intrinsic to human nature and therefore ineradicable.

With the entrenchment of this view, a paralyzing contradiction has developed in human affairs. On the one hand, people of all nations proclaim not only their readiness but their longing for peace and harmony, for an end to the harrowing apprehensions tormenting their daily lives. On the other, uncritical assent is given to the proposition that human beings are incorrigibly selfish and aggressive and thus incapable of erecting a social system at once progressive and peaceful, dynamic and harmonious, a system giving free play to individual creativity and initiative but based on co-operation and reciprocity.

As the need for peace becomes more urgent, this fundamental contradiction, which hinders its realization, demands a reassessment of the assumptions upon which the commonly held view of mankind’s historical predicament is based. Dispassionately examined, the evidence reveals that such conduct, far from expressing man’s true self, represents a distortion of the human spirit. Satisfaction on this point will enable all people to set in motion constructive social forces which, because they are consistent with human nature, will encourage harmony and co-operation instead of war and conflict.

To choose such a course is not to deny humanity’s past but to understand it. The Bahá’í Faith regards the current world confusion and calamitous condition in human affairs as a natural phase in an organic process leading ultimately and irresistibly to the unification of the human race in a single social order whose boundaries are those of the planet. The human race, as a distinct, organic unit, has passed through evolutionary stages analogous to the stages of infancy and childhood in the lives of its individual members, and is now in the culminating period of its turbulent adolescence approaching its long-awaited coming of age.

A candid acknowledgement that prejudice, war and exploitation have been the expression of immature stages in a vast historical process and that the human race is today experiencing the unavoidable tumult which marks its collective coming of age is not a reason for despair but a prerequisite to undertaking the stupendous enterprise of building a peaceful world. That such an enterprise is possible, that the necessary constructive forces do exist, that unifying social structures can be erected, is the theme we urge you to examine.

Whatever suffering and turmoil the years immediately ahead may hold, however dark the immediate circumstances, the Bahá’í community believes that humanity can confront this supreme trial with confidence in its ultimate outcome. Far from signalizing the end of civilization, the convulsive changes towards which humanity is being ever more rapidly impelled will serve to release the “potentialities inherent in the station of man” and reveal “the full measure of his destiny on earth, the innate excellence of his reality”.

The Universal House of Justice
October 1985
''';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final text = pwp.trim();
    final style = GoogleFonts.notoSerif(fontSize: 36, height: 1.5);
    final dropCapStyle = GoogleFonts.bellefair();

    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: PaginatedExample(
          text: text,
          style: style,
          dropCapStyle: dropCapStyle,
        ),
      ),
    );
  }
}

class PaginatedExample extends StatefulWidget {
  const PaginatedExample({
    super.key,
    required this.text,
    required this.style,
    required this.dropCapStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle dropCapStyle;

  @override
  State<PaginatedExample> createState() => _PaginatedExampleState();
}

class _PaginatedExampleState extends State<PaginatedExample>
    with SingleTickerProviderStateMixin {
  late Future _googleFontsPending;
  late PaginatedController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = PaginatedController(PaginateData(
      text: widget.text,
      dropCapLines: 3,
      style: widget.style,
      dropCapStyle: widget.dropCapStyle,
      pageBreakType: PageBreakType.paragraph,
      breakLines: 1,
      resizeTolerance: 3,
      parseInlineMarkdown: true,
    ));
    _googleFontsPending = GoogleFonts.pendingFonts([
      widget.style,
      widget.dropCapStyle,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _googleFontsPending,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator.adaptive();
          }

          final reverse = _controller.pageIndex < _controller.previousPageIndex;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: PaginatedText(
              _controller,
              builder: (context, child) {
                return DefaultTextStyle(
                  style: widget.style,
                  child: Column(
                    children: [
                      Text('The Promise of World Peace',
                          style: widget.dropCapStyle.copyWith(
                              fontSize: 40, fontStyle: FontStyle.italic)),
                      Expanded(
                        child: PageTransitionSwitcher(
                          duration: const Duration(seconds: 1),
                          reverse: reverse,
                          transitionBuilder:
                              (child, primaryAnimation, secondaryAnimation) {
                            const offscreen = Offset(-1.5, 0.0);
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset.zero,
                                end: offscreen,
                              ).animate(secondaryAnimation),
                              child: FadeTransition(
                                opacity: Tween<double>(
                                  begin: 0.0,
                                  end: 1.0,
                                ).animate(primaryAnimation),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            key: ValueKey(_controller.currentPage.pageIndex),
                            padding: const EdgeInsets.all(40),
                            child: child,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                          'Page ${_controller.pageNumber} of ${_controller.numPages}',
                          style: widget.style.copyWith(fontSize: 24)),
                      const SizedBox(height: 20),
                      ButtonBar(
                        alignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _controller.isFirst
                                ? null
                                : () {
                                    setState(() {
                                      _controller.previous();
                                    });
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text('Prev', style: TextStyle(fontSize: 30)),
                            ),
                          ),
                          TextButton(
                            onPressed: _controller.isLast
                                ? null
                                : () {
                                    setState(() {
                                      _controller.next();
                                    });
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text('Next', style: TextStyle(fontSize: 30)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
  }
}

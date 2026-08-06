import '../models/bouquet_order.dart';
import '../models/customer_profile.dart';
import '../models/flower.dart';

// ── Customer pool ──────────────────────────────────────────────────────────────

final List<CustomerProfile> customerPool = [
  // ── Regulars ──────────────────────────────────────────────────────────────

  const CustomerProfile(
    id: 'c1',
    name: 'Sophie',
    portrait: '👩',
    mood: CustomerMood.excited,
    isRegular: true,
    loyaltyMultiplier: 1.1,
    backstorySnippets: [
      'Sophie mentioned her job at the art gallery started last spring. She says flowers help her think about colour theory.',
      'Sophie told you she sends a bouquet to her mum two towns over every week. They went through a rough patch years ago and flowers are their way of saying sorry.',
      'Sophie asked if you could make the bouquet extra special — she\'s visiting her mum in person for the first time in four years. Her mum turns 60 next Sunday.',
    ],
    lifeEventHint:
        '"Mum turns 60 this Sunday and I\'m finally visiting in person. Please — the most beautiful thing you\'ve ever made. She deserves it."',
    rivalMention:
        'Oh, and I walked past Petal & Co. this morning. Their window was nice, I suppose. But it\'s not the same.',
  ),

  const CustomerProfile(
    id: 'c2',
    name: 'James',
    portrait: '👨',
    mood: CustomerMood.neutral,
    rivalMention:
        'My wife suggested I try Petal & Co. I told her I had a better idea.',
  ),

  const CustomerProfile(
    id: 'c3',
    name: 'Mrs. Chen',
    portrait: '👵',
    mood: CustomerMood.sad,
    isRegular: true,
    loyaltyMultiplier: 1.15,
    backstorySnippets: [
      'Mrs. Chen whispered that she\'s been coming every week since losing her husband last autumn. The flowers help, she said.',
      'Mrs. Chen mentioned her daughter moved to Vancouver and rarely calls. She said quietly: "Flowers don\'t leave."',
      'Mrs. Chen told you she was a florist herself, long ago, in another country. She said your shop reminds her of home.',
    ],
    lifeEventHint:
        '"My granddaughter is flying in from Vancouver. First time in six years. I need something perfect. Something that says welcome home."',
    rivalMention:
        'Someone in my building told me about Petal & Co. I said I already have my place.',
  ),

  const CustomerProfile(
    id: 'c4',
    name: 'Luca',
    portrait: '🧑',
    mood: CustomerMood.anxious,
  ),

  const CustomerProfile(
    id: 'c5',
    name: 'Priya',
    portrait: '👩‍🦱',
    mood: CustomerMood.happy,
    rivalMention:
        'My flatmate keeps going to Petal & Co. but honestly the vibe is so cold in there.',
  ),

  const CustomerProfile(
    id: 'c6',
    name: 'Tom',
    portrait: '👨‍🦳',
    mood: CustomerMood.neutral,
  ),

  const CustomerProfile(
    id: 'c7',
    name: 'Mei',
    portrait: '👩‍🦰',
    mood: CustomerMood.excited,
    rivalMention:
        'I saw Petal & Co. put up a new sign. Very corporate. Very not-me.',
  ),

  const CustomerProfile(
    id: 'c8',
    name: 'Elena',
    portrait: '👱‍♀️',
    mood: CustomerMood.happy,
    isRegular: true,
    loyaltyMultiplier: 1.1,
    backstorySnippets: [
      'Elena mentioned she teaches Year 4. She brings flowers to her classroom every Monday morning — "it changes everything," she said.',
      'Elena said one of her students has been struggling at home. She\'s been sending a flower home with them every Friday, tucked in their bag.',
      'Elena beamed and said that student gave her a drawing of your flower shop last week. She\'s framed it above her desk.',
    ],
    lifeEventHint:
        '"It\'s the last day of term and I want to give every child in my class a single flower. It\'s been a hard year. They deserve a good ending."',
    rivalMention:
        'One of my students asked if I bought these at Petal & Co. I said no, we have somewhere much better.',
  ),

  const CustomerProfile(
    id: 'c9',
    name: 'Diego',
    portrait: '🧔',
    mood: CustomerMood.excited,
  ),

  const CustomerProfile(
    id: 'c10',
    name: 'Rosa',
    portrait: '👩‍🦳',
    mood: CustomerMood.sad,
    rivalMention:
        'My neighbour says Petal & Co. is cheaper. I told her some things aren\'t about price.',
  ),

  const CustomerProfile(
    id: 'c11',
    name: 'Sam',
    portrait: '🧑‍🦱',
    mood: CustomerMood.neutral,
  ),

  const CustomerProfile(
    id: 'c12',
    name: 'Nadia',
    portrait: '👩‍🦲',
    mood: CustomerMood.happy,
    rivalMention:
        'Have you seen that Petal & Co. opened up the road? Their Instagram looks good but it\'s a bit soulless in person.',
  ),

  const CustomerProfile(
    id: 'c13',
    name: 'Oliver',
    portrait: '👦',
    mood: CustomerMood.excited,
  ),

  const CustomerProfile(
    id: 'c14',
    name: 'Fatima',
    portrait: '🧕',
    mood: CustomerMood.sad,
    isRegular: true,
    loyaltyMultiplier: 1.2,
    backstorySnippets: [
      'Fatima mentioned she orders flowers whenever her anxiety gets bad. "It\'s part of the routine," she said. "Something alive, something real."',
      'Fatima told you she\'s been in therapy for two years. "Your flowers are on my list of small joys. My therapist approves."',
      'Fatima said she\'s writing a book about small moments that hold you together when nothing else does. She smiled quietly. "You might be in it."',
    ],
    lifeEventHint:
        '"The book is finished. My publisher called this morning. I need something that feels like relief and joy at once — something I\'ll remember forever."',
    rivalMention:
        'I walked past Petal & Co. yesterday. Very clean, very cold. This is not a cold flowers kind of day.',
  ),

  const CustomerProfile(
    id: 'c15',
    name: 'Marcus',
    portrait: '👨‍🦱',
    mood: CustomerMood.neutral,
  ),

  const CustomerProfile(
    id: 'c16',
    name: 'Yuki',
    portrait: '👩',
    mood: CustomerMood.happy,
    rivalMention:
        'I passed Petal & Co. — very polished, very lifeless. I prefer it here.',
  ),

  const CustomerProfile(
    id: 'c17',
    name: 'Patrick',
    portrait: '👨‍🦰',
    mood: CustomerMood.neutral,
  ),

  const CustomerProfile(
    id: 'c18',
    name: 'Amara',
    portrait: '👩‍🦱',
    mood: CustomerMood.excited,
    isRegular: true,
    loyaltyMultiplier: 1.12,
    backstorySnippets: [
      'Amara runs the community garden on Elm Street. She said your flowers inspired her to plant dahlias this season.',
      'Amara told you the community garden won a local award. She pressed a dried sunflower into your hand as thanks.',
      'Amara whispered that a developer wants to build on the garden\'s land. She\'s fighting it. "I keep flowers on my desk to remember what\'s worth fighting for."',
    ],
    lifeEventHint:
        '"We won. The garden stays. I want the most celebratory bouquet you\'ve ever made — for the whole neighbourhood."',
    rivalMention: null,
  ),

  const CustomerProfile(
    id: 'c19',
    name: 'Ben',
    portrait: '🧑‍🦳',
    mood: CustomerMood.sad,
  ),

  const CustomerProfile(
    id: 'c20',
    name: 'Chloe',
    portrait: '👧',
    mood: CustomerMood.excited,
  ),
];

// ── Tier 1 orders — Days 1–5, simple vibes, small bunches ─────────────────────

final List<BouquetOrder> _earlyOrders = [
  BouquetOrder(
    id: 'o1',
    customer: customerPool[0],
    description: 'Romantic Anniversary',
    hint: '"It\'s our 10th anniversary. She says flowers are old-fashioned — she\'s wrong. Help me prove it."',
    requiredVibes: [VibeTag.romantic, VibeTag.elegant],
    minFlowers: 4, maxFlowers: 7, basePayment: 48,
  ),
  BouquetOrder(
    id: 'o2',
    customer: customerPool[6],
    description: 'Birthday Party',
    hint: '"My best friend turns 30 today! Big, loud, joyful — she doesn\'t do subtle."',
    requiredVibes: [VibeTag.cheerful, VibeTag.vibrant],
    minFlowers: 4, maxFlowers: 7, basePayment: 38,
  ),
  BouquetOrder(
    id: 'o4',
    customer: customerPool[3],
    description: 'First Date',
    hint: '"I — I\'m going to propose tonight. I\'ve never been so terrified. Something hopeful. Fresh."',
    requiredVibes: [VibeTag.romantic, VibeTag.fresh],
    minFlowers: 3, maxFlowers: 6, basePayment: 38,
  ),
  BouquetOrder(
    id: 'o5',
    customer: customerPool[4],
    description: 'Housewarming',
    hint: '"My sister just moved into her first place — she has a garden view and wants something wild and earthy."',
    requiredVibes: [VibeTag.wild, VibeTag.natural],
    minFlowers: 4, maxFlowers: 7, basePayment: 36,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o7',
    customer: customerPool[1],
    description: 'Just Because',
    hint: '"Something cosy and warm — for myself, honestly. I deserve it."',
    requiredVibes: [VibeTag.cozy, VibeTag.fresh],
    minFlowers: 3, maxFlowers: 5, basePayment: 28,
  ),
  BouquetOrder(
    id: 'o8',
    customer: customerPool[0],
    description: 'Thank You',
    hint: '"My neighbour kept my cat for two weeks. Something joyful, soft — she\'s a gentle soul."',
    requiredVibes: [VibeTag.cheerful, VibeTag.delicate],
    minFlowers: 3, maxFlowers: 6, basePayment: 30,
  ),
  BouquetOrder(
    id: 'o9',
    customer: customerPool[7],
    description: 'Baby Shower',
    hint: '"She\'s having twins! Soft, fresh, hopeful — something that smells like a new beginning."',
    requiredVibes: [VibeTag.delicate, VibeTag.fresh, VibeTag.soft],
    minFlowers: 4, maxFlowers: 7, basePayment: 36,
  ),
  BouquetOrder(
    id: 'o12',
    customer: customerPool[4],
    description: 'Get Well Soon',
    hint: '"My colleague\'s in hospital. Something bright and cheerful to lift the mood of that awful room."',
    requiredVibes: [VibeTag.fresh, VibeTag.cheerful],
    minFlowers: 3, maxFlowers: 6, basePayment: 30,
  ),
  BouquetOrder(
    id: 'o13',
    customer: customerPool[8],
    description: 'Apology Bouquet',
    hint: '"I said something stupid. Very stupid. Something humble and romantic — I need her to forgive me."',
    requiredVibes: [VibeTag.romantic, VibeTag.soft],
    minFlowers: 3, maxFlowers: 6, basePayment: 32,
  ),
  BouquetOrder(
    id: 'o14',
    customer: customerPool[10],
    description: "Mother's Day",
    hint: '"Mum loves her garden. She always says flowers should feel like a warm hug."',
    requiredVibes: [VibeTag.romantic, VibeTag.cozy],
    minFlowers: 4, maxFlowers: 7, basePayment: 42,
  ),
  BouquetOrder(
    id: 'o17',
    customer: customerPool[9],
    description: 'Autumn Harvest',
    hint: '"For the dining table. Something that looks like autumn — rustic, warm, a bit wild."',
    requiredVibes: [VibeTag.rustic, VibeTag.natural],
    minFlowers: 4, maxFlowers: 7, basePayment: 35,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o19',
    customer: customerPool[11],
    description: 'Wildflower Field',
    hint: '"I want it to look like I just ran through a meadow and grabbed everything. Natural, messy, alive."',
    requiredVibes: [VibeTag.wild, VibeTag.fresh, VibeTag.natural],
    minFlowers: 4, maxFlowers: 8, basePayment: 33,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o21',
    customer: customerPool[9],
    description: 'Cottage Garden',
    hint: '"I want my kitchen to smell like an old English garden — cosy, wild, proper."',
    requiredVibes: [VibeTag.cozy, VibeTag.natural],
    minFlowers: 4, maxFlowers: 7, basePayment: 34,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o23',
    customer: customerPool[3],
    description: 'Secret Admirer',
    hint: '"Something that says... feelings. You know what I mean. Please."',
    requiredVibes: [VibeTag.romantic],
    minFlowers: 3, maxFlowers: 5, basePayment: 28,
  ),
  BouquetOrder(
    id: 'o29',
    customer: customerPool[10],
    description: 'New Baby',
    hint: '"My niece was born this morning! Something soft and sweet, like she is."',
    requiredVibes: [VibeTag.soft, VibeTag.delicate],
    minFlowers: 3, maxFlowers: 6, basePayment: 32,
  ),
  BouquetOrder(
    id: 'o32',
    customer: customerPool[1],
    description: "Friend's Birthday",
    hint: '"Nothing too serious — she\'ll just put it on Instagram anyway."',
    requiredVibes: [VibeTag.cheerful, VibeTag.vibrant],
    minFlowers: 3, maxFlowers: 6, basePayment: 28,
  ),
  BouquetOrder(
    id: 'o33',
    customer: customerPool[15],
    description: 'Self-Care Sunday',
    hint: '"I have been working non-stop for three months. I need something that forces me to slow down."',
    requiredVibes: [VibeTag.cozy, VibeTag.soft],
    minFlowers: 3, maxFlowers: 5, basePayment: 26,
  ),
  BouquetOrder(
    id: 'o34',
    customer: customerPool[12],
    description: 'Exam Celebration',
    hint: '"My little sister passed her driving test on the fifth attempt. She cried. We all cried."',
    requiredVibes: [VibeTag.cheerful, VibeTag.fresh],
    minFlowers: 3, maxFlowers: 6, basePayment: 28,
  ),
  BouquetOrder(
    id: 'o35',
    customer: customerPool[16],
    description: 'Sorry I Forgot',
    hint: '"I forgot our anniversary. Completely. I need you to help me not be divorced by Tuesday."',
    requiredVibes: [VibeTag.romantic, VibeTag.elegant],
    minFlowers: 4, maxFlowers: 7, basePayment: 42,
  ),
  BouquetOrder(
    id: 'o36',
    customer: customerPool[5],
    description: 'Table Centrepiece',
    hint: '"Dinner party on Saturday. Something fresh and natural — not too fussy."',
    requiredVibes: [VibeTag.fresh, VibeTag.natural],
    minFlowers: 3, maxFlowers: 6, basePayment: 30,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o37',
    customer: customerPool[19],
    description: 'Cheer Up Gift',
    hint: '"My roommate has been in a slump. Something that just — radiates happiness."',
    requiredVibes: [VibeTag.cheerful, VibeTag.vibrant],
    minFlowers: 3, maxFlowers: 6, basePayment: 28,
  ),
  BouquetOrder(
    id: 'o38',
    customer: customerPool[18],
    description: 'Retirement Gift',
    hint: '"My boss is retiring after 32 years. She was tough. She deserves something classic."',
    requiredVibes: [VibeTag.elegant, VibeTag.traditional],
    minFlowers: 4, maxFlowers: 7, basePayment: 40,
  ),
  BouquetOrder(
    id: 'o39',
    customer: customerPool[4],
    description: 'New Job',
    hint: '"I got the job! I want to treat myself before the imposter syndrome kicks in."',
    requiredVibes: [VibeTag.bold, VibeTag.fresh],
    minFlowers: 3, maxFlowers: 6, basePayment: 30,
  ),
  BouquetOrder(
    id: 'o40',
    customer: customerPool[14],
    description: 'Sunday Market Stall',
    hint: '"For my stall at the weekend market. Something bright that makes people stop and look."',
    requiredVibes: [VibeTag.vibrant, VibeTag.natural],
    minFlowers: 4, maxFlowers: 7, basePayment: 32,
  ),
];

// ── Tier 2 orders — Days 3–12, medium complexity, more vibe combinations ────────

final List<BouquetOrder> _midOrders = [
  BouquetOrder(
    id: 'o3',
    customer: customerPool[2],
    description: 'In Memoriam',
    hint: '"For my husband\'s funeral. Something peaceful and gentle, please. He loved quiet things."',
    requiredVibes: [VibeTag.sympathy, VibeTag.delicate],
    minFlowers: 5, maxFlowers: 8, basePayment: 55,
  ),
  BouquetOrder(
    id: 'o6',
    customer: customerPool[5],
    description: 'Corporate Gift',
    hint: '"It\'s for my CEO. Tasteful. Understated. Nothing that\'ll make HR send a memo."',
    requiredVibes: [VibeTag.elegant, VibeTag.delicate],
    minFlowers: 4, maxFlowers: 7, basePayment: 50,
  ),
  BouquetOrder(
    id: 'o11',
    customer: customerPool[12],
    description: 'Graduation',
    hint: '"My little brother just got his PhD. He worked SO hard. Make it a statement."',
    requiredVibes: [VibeTag.vibrant, VibeTag.bold, VibeTag.cheerful],
    minFlowers: 5, maxFlowers: 8, basePayment: 42,
  ),
  BouquetOrder(
    id: 'o15',
    customer: customerPool[8],
    description: "Valentine's Day",
    hint: '"She deserves the most romantic thing you\'ve ever made. Dazzle her."',
    requiredVibes: [VibeTag.romantic, VibeTag.vibrant, VibeTag.elegant],
    minFlowers: 5, maxFlowers: 8, basePayment: 62,
  ),
  BouquetOrder(
    id: 'o16',
    customer: customerPool[13],
    description: 'Día de los Muertos',
    hint: '"For my grandmother\'s ofrenda. Bold, festive, full of life — that\'s how she lived."',
    requiredVibes: [VibeTag.festive, VibeTag.bold, VibeTag.mystical],
    minFlowers: 5, maxFlowers: 9, basePayment: 52,
  ),
  BouquetOrder(
    id: 'o18',
    customer: customerPool[14],
    description: 'Winter Holiday',
    hint: '"For the Christmas table centrepiece. Festive, dramatic, lots of green."',
    requiredVibes: [VibeTag.festive, VibeTag.bold, VibeTag.natural],
    minFlowers: 5, maxFlowers: 9, basePayment: 48,
  ),
  BouquetOrder(
    id: 'o22',
    customer: customerPool[11],
    description: 'Boho Wedding',
    hint: '"Outdoor ceremony in a field. Wildly romantic — think bare feet on grass, flower crowns."',
    requiredVibes: [VibeTag.wild, VibeTag.romantic, VibeTag.delicate],
    minFlowers: 5, maxFlowers: 9, basePayment: 58,
  ),
  BouquetOrder(
    id: 'o24',
    customer: customerPool[2],
    description: 'Sympathy Condolences',
    hint: '"My friend lost her mother this week. Something peaceful. No bright colours."',
    requiredVibes: [VibeTag.sympathy, VibeTag.elegant, VibeTag.traditional],
    minFlowers: 5, maxFlowers: 8, basePayment: 50,
  ),
  BouquetOrder(
    id: 'o25',
    customer: customerPool[12],
    description: 'School Prom',
    hint: '"It\'s for my date! It needs to be the most amazing thing she\'s ever seen. She likes pink."',
    requiredVibes: [VibeTag.vibrant, VibeTag.elegant, VibeTag.romantic],
    minFlowers: 4, maxFlowers: 7, basePayment: 44,
  ),
  BouquetOrder(
    id: 'o26',
    customer: customerPool[6],
    description: 'Festival Celebration',
    hint: '"Diwali is coming! Big, bright, joyful — make it as festive as possible!"',
    requiredVibes: [VibeTag.festive, VibeTag.vibrant, VibeTag.bold],
    minFlowers: 5, maxFlowers: 9, basePayment: 46,
  ),
  BouquetOrder(
    id: 'o27',
    customer: customerPool[5],
    description: 'Farewell Gift',
    hint: '"My colleague is moving to Tokyo. Something elegant to wish her well. Bittersweet."',
    requiredVibes: [VibeTag.elegant, VibeTag.cozy],
    minFlowers: 4, maxFlowers: 7, basePayment: 40,
  ),
  BouquetOrder(
    id: 'o30',
    customer: customerPool[13],
    description: 'Mystical Retreat',
    hint: '"For our yoga studio\'s opening. Ethereal, mystical — something that feels sacred."',
    requiredVibes: [VibeTag.mystical, VibeTag.delicate, VibeTag.elegant],
    minFlowers: 5, maxFlowers: 9, basePayment: 52,
  ),
  BouquetOrder(
    id: 'o31',
    customer: customerPool[8],
    description: 'Rustic Farm Wedding',
    hint: '"Barn wedding. Hay bales. Wild herbs. Make it look like it grew there naturally."',
    requiredVibes: [VibeTag.rustic, VibeTag.wild, VibeTag.natural],
    minFlowers: 5, maxFlowers: 9, basePayment: 55,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o41',
    customer: customerPool[17],
    description: 'Gallery Opening',
    hint: '"For our new exhibition launch. The art is minimal. The flowers should be the drama."',
    requiredVibes: [VibeTag.bold, VibeTag.exotic, VibeTag.elegant],
    minFlowers: 5, maxFlowers: 9, basePayment: 60,
  ),
  BouquetOrder(
    id: 'o42',
    customer: customerPool[7],
    description: 'Engagement Party',
    hint: '"She said yes! We\'re throwing a party this weekend. Romantic, celebratory, joyful."',
    requiredVibes: [VibeTag.romantic, VibeTag.cheerful, VibeTag.elegant],
    minFlowers: 5, maxFlowers: 9, basePayment: 52,
  ),
  BouquetOrder(
    id: 'o43',
    customer: customerPool[18],
    description: 'Hospital Corridor',
    hint: '"For the paediatric ward. Children should have colour and hope, not beige walls."',
    requiredVibes: [VibeTag.cheerful, VibeTag.vibrant, VibeTag.fresh],
    minFlowers: 5, maxFlowers: 8, basePayment: 48,
  ),
  BouquetOrder(
    id: 'o44',
    customer: customerPool[16],
    description: 'Traditional Wedding',
    hint: '"Classic church wedding. White, cream, soft. The family is traditional — please no surprises."',
    requiredVibes: [VibeTag.elegant, VibeTag.traditional, VibeTag.delicate],
    minFlowers: 6, maxFlowers: 10, basePayment: 65,
  ),
  BouquetOrder(
    id: 'o45',
    customer: customerPool[15],
    description: 'Lunar New Year',
    hint: '"For the family table on New Year\'s Eve. Joyful, lucky, prosperous — red and gold if possible!"',
    requiredVibes: [VibeTag.festive, VibeTag.vibrant, VibeTag.bold],
    minFlowers: 5, maxFlowers: 9, basePayment: 50,
  ),
  BouquetOrder(
    id: 'o46',
    customer: customerPool[9],
    description: 'Memorial Garden',
    hint: '"We\'re planting a memorial garden for our dad. Something natural and timeless."',
    requiredVibes: [VibeTag.sympathy, VibeTag.natural, VibeTag.rustic],
    minFlowers: 5, maxFlowers: 8, basePayment: 48,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o47',
    customer: customerPool[19],
    description: 'Prom Night',
    hint: '"My mum says I have to bring flowers. But I want them to actually look cool, not mum-cool."',
    requiredVibes: [VibeTag.vibrant, VibeTag.bold],
    minFlowers: 4, maxFlowers: 7, basePayment: 40,
  ),
  BouquetOrder(
    id: 'o48',
    customer: customerPool[6],
    description: 'Eid Celebration',
    hint: '"Eid al-Fitr is tomorrow! Joyful, generous, warm — the whole extended family is coming."',
    requiredVibes: [VibeTag.festive, VibeTag.cozy, VibeTag.vibrant],
    minFlowers: 5, maxFlowers: 9, basePayment: 48,
  ),
  BouquetOrder(
    id: 'o49',
    customer: customerPool[11],
    description: 'Book Club Hostess',
    hint: '"I\'m hosting book club. Something literary and a bit romantic. We\'re reading Jane Austen."',
    requiredVibes: [VibeTag.romantic, VibeTag.traditional, VibeTag.elegant],
    minFlowers: 4, maxFlowers: 7, basePayment: 40,
  ),
  BouquetOrder(
    id: 'o50',
    customer: customerPool[3],
    description: 'Marriage Proposal',
    hint: '"Tonight\'s the night. I\'ve planned it down to the last second. The flowers are the last piece."',
    requiredVibes: [VibeTag.romantic, VibeTag.elegant, VibeTag.soft],
    minFlowers: 5, maxFlowers: 8, basePayment: 58,
  ),
  BouquetOrder(
    id: 'o51',
    customer: customerPool[4],
    description: 'Holi Festival',
    hint: '"Holi! Colour! Spring! Joy! Make the most vibrant thing you\'ve ever assembled."',
    requiredVibes: [VibeTag.festive, VibeTag.vibrant, VibeTag.cheerful],
    minFlowers: 5, maxFlowers: 9, basePayment: 45,
  ),
  BouquetOrder(
    id: 'o52',
    customer: customerPool[13],
    description: 'Vow Renewal',
    hint: '"Twenty-five years together. Same love, more wisdom. Something timeless, please."',
    requiredVibes: [VibeTag.romantic, VibeTag.elegant, VibeTag.traditional],
    minFlowers: 5, maxFlowers: 9, basePayment: 58,
  ),
  BouquetOrder(
    id: 'o53',
    customer: customerPool[1],
    description: 'Dad\'s Birthday',
    hint: '"Dad\'s turning 60. He\'s a big tough man who secretly loves flowers. Don\'t tell him I said that."',
    requiredVibes: [VibeTag.bold, VibeTag.natural],
    minFlowers: 4, maxFlowers: 7, basePayment: 38,
  ),
  BouquetOrder(
    id: 'o54',
    customer: customerPool[17],
    description: 'Photography Shoot',
    hint: '"For a fashion shoot. The flowers need to be a MOMENT. Structural, dramatic, statement."',
    requiredVibes: [VibeTag.bold, VibeTag.exotic, VibeTag.vibrant],
    minFlowers: 5, maxFlowers: 9, basePayment: 55,
  ),
  BouquetOrder(
    id: 'o55',
    customer: customerPool[18],
    description: 'Grief Support',
    hint: '"She just found out her diagnosis. I don\'t know what to say. Maybe flowers can say it for me."',
    requiredVibes: [VibeTag.sympathy, VibeTag.soft, VibeTag.delicate],
    minFlowers: 4, maxFlowers: 7, basePayment: 46,
  ),
];

// ── Tier 3 orders — Days 8–20, complex vibes, premium pay ──────────────────────

final List<BouquetOrder> _lateOrders = [
  BouquetOrder(
    id: 'o10',
    customer: customerPool[7],
    description: 'Wedding Ceremony',
    hint: '"I\'m the maid of honour. She wants it romantic, elegant, and a little extra. Budget isn\'t an issue."',
    requiredVibes: [VibeTag.romantic, VibeTag.elegant, VibeTag.luxurious],
    minFlowers: 6, maxFlowers: 10, basePayment: 72,
  ),
  BouquetOrder(
    id: 'o20',
    customer: customerPool[7],
    description: 'Luxury Gift',
    hint: '"It\'s for a very important client. Spare no expense. It should say: \'we are serious people\'."',
    requiredVibes: [VibeTag.elegant, VibeTag.exotic, VibeTag.luxurious],
    minFlowers: 6, maxFlowers: 10, basePayment: 88,
  ),
  BouquetOrder(
    id: 'o28',
    customer: customerPool[14],
    description: 'Charity Auction Centrepiece',
    hint: '"It\'s the centrepiece for a gala. Everyone will see it. Luxurious, statement piece."',
    requiredVibes: [VibeTag.luxurious, VibeTag.elegant, VibeTag.bold],
    minFlowers: 7, maxFlowers: 12, basePayment: 85,
  ),
  BouquetOrder(
    id: 'o56',
    customer: customerPool[14],
    description: 'Black Tie Gala',
    hint: '"For the mayor\'s table at the annual gala. Only the finest will do."',
    requiredVibes: [VibeTag.luxurious, VibeTag.elegant, VibeTag.exotic],
    minFlowers: 7, maxFlowers: 12, basePayment: 95,
  ),
  BouquetOrder(
    id: 'o57',
    customer: customerPool[17],
    description: 'Michelin Star Opening',
    hint: '"New restaurant opening. The chef is obsessive. Flowers must match the tasting menu aesthetic."',
    requiredVibes: [VibeTag.exotic, VibeTag.elegant, VibeTag.mystical],
    minFlowers: 6, maxFlowers: 10, basePayment: 80,
  ),
  BouquetOrder(
    id: 'o58',
    customer: customerPool[0],
    description: 'Gallery Centrepiece',
    hint: '"Our new wing opens this Friday. Five-metre installation. Push every boundary."',
    requiredVibes: [VibeTag.bold, VibeTag.exotic, VibeTag.mystical],
    minFlowers: 8, maxFlowers: 14, basePayment: 100,
  ),
  BouquetOrder(
    id: 'o59',
    customer: customerPool[7],
    description: 'Royal-Inspired',
    hint: '"I\'m obsessed with the royals. I want something fit for a palace. Utterly luxurious."',
    requiredVibes: [VibeTag.luxurious, VibeTag.romantic, VibeTag.traditional],
    minFlowers: 7, maxFlowers: 11, basePayment: 90,
  ),
  BouquetOrder(
    id: 'o60',
    customer: customerPool[5],
    description: 'CEO Welcome Bouquet',
    hint: '"New CEO starts Monday. Board wants flowers in the boardroom. Powerful, but tasteful."',
    requiredVibes: [VibeTag.elegant, VibeTag.bold, VibeTag.luxurious],
    minFlowers: 6, maxFlowers: 10, basePayment: 78,
  ),
  BouquetOrder(
    id: 'o61',
    customer: customerPool[15],
    description: 'Cherry Blossom Themed',
    hint: '"For a Japanese-inspired spring party. Delicate, magical — like the moment before petals fall."',
    requiredVibes: [VibeTag.delicate, VibeTag.mystical, VibeTag.soft],
    minFlowers: 5, maxFlowers: 9, basePayment: 65,
  ),
  BouquetOrder(
    id: 'o62',
    customer: customerPool[16],
    description: 'Exotic Safari',
    hint: '"Jungle-themed party. Wild, dramatic, tropical. I want people to feel like they\'re somewhere extraordinary."',
    requiredVibes: [VibeTag.exotic, VibeTag.wild, VibeTag.bold],
    minFlowers: 6, maxFlowers: 10, basePayment: 72,
  ),
  BouquetOrder(
    id: 'o63',
    customer: customerPool[17],
    description: 'Music Video Shoot',
    hint: '"We\'re shooting tomorrow. The director wants flowers that are \'otherworldly\'. His word, not mine."',
    requiredVibes: [VibeTag.mystical, VibeTag.exotic, VibeTag.vibrant],
    minFlowers: 6, maxFlowers: 10, basePayment: 75,
  ),
  BouquetOrder(
    id: 'o64',
    customer: customerPool[13],
    description: 'Sufi Ceremony',
    hint: '"For a sacred gathering. Flowers must carry a spiritual weight — mystical, ancient, humble."',
    requiredVibes: [VibeTag.mystical, VibeTag.traditional, VibeTag.sympathy],
    minFlowers: 5, maxFlowers: 9, basePayment: 62,
  ),
  BouquetOrder(
    id: 'o65',
    customer: customerPool[18],
    description: 'Five Star Hotel Lobby',
    hint: '"Weekly arrangement for the hotel reception. Guests fly in from everywhere — make it world-class."',
    requiredVibes: [VibeTag.luxurious, VibeTag.elegant, VibeTag.exotic],
    minFlowers: 7, maxFlowers: 12, basePayment: 88,
  ),
  BouquetOrder(
    id: 'o66',
    customer: customerPool[9],
    description: 'Exotic Midsummer',
    hint: '"Midsummer dinner. Long table in the garden. Lush, overflowing, theatrical."',
    requiredVibes: [VibeTag.exotic, VibeTag.luxurious, VibeTag.natural],
    minFlowers: 7, maxFlowers: 12, basePayment: 82,
  ),
  BouquetOrder(
    id: 'o67',
    customer: customerPool[12],
    description: 'Architecture Award',
    hint: '"Won a design award. My firm wants something that feels as considered as our buildings."',
    requiredVibes: [VibeTag.elegant, VibeTag.bold, VibeTag.exotic],
    minFlowers: 6, maxFlowers: 10, basePayment: 75,
  ),
  BouquetOrder(
    id: 'o68',
    customer: customerPool[11],
    description: 'Perfume Launch',
    hint: '"For a fragrance brand event. The scent is \'dark rose and leather\'. Match the energy."',
    requiredVibes: [VibeTag.exotic, VibeTag.mystical, VibeTag.luxurious],
    minFlowers: 6, maxFlowers: 10, basePayment: 80,
  ),
  BouquetOrder(
    id: 'o69',
    customer: customerPool[10],
    description: 'Once-in-a-Lifetime',
    hint: '"My grandmother is 100 years old today. I need the most extraordinary thing you\'ve ever made."',
    requiredVibes: [VibeTag.luxurious, VibeTag.elegant, VibeTag.traditional],
    minFlowers: 8, maxFlowers: 14, basePayment: 100,
  ),
  BouquetOrder(
    id: 'o70',
    customer: customerPool[17],
    description: 'Haute Couture Show',
    hint: '"Front row at the fashion show. The flowers will be photographed. Make them fashion."',
    requiredVibes: [VibeTag.exotic, VibeTag.bold, VibeTag.elegant],
    minFlowers: 6, maxFlowers: 10, basePayment: 85,
  ),
  BouquetOrder(
    id: 'o71',
    customer: customerPool[6],
    description: 'New Year\'s Eve Party',
    hint: '"Countdown to midnight. Forty guests. Everything should feel like the year\'s grand finale."',
    requiredVibes: [VibeTag.festive, VibeTag.luxurious, VibeTag.bold],
    minFlowers: 7, maxFlowers: 12, basePayment: 82,
  ),
  BouquetOrder(
    id: 'o72',
    customer: customerPool[4],
    description: 'Spa & Wellness Opening',
    hint: '"New wellness centre opening. Tranquil, healing, natural — guests should feel peace the moment they walk in."',
    requiredVibes: [VibeTag.delicate, VibeTag.soft, VibeTag.natural],
    minFlowers: 6, maxFlowers: 10, basePayment: 68,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o73',
    customer: customerPool[19],
    description: 'Ballet Recital',
    hint: '"For my dance teacher. She\'s been teaching for 40 years. Something as graceful as she is."',
    requiredVibes: [VibeTag.elegant, VibeTag.delicate, VibeTag.romantic],
    minFlowers: 5, maxFlowers: 9, basePayment: 62,
  ),
  BouquetOrder(
    id: 'o74',
    customer: customerPool[3],
    description: 'Midnight Garden',
    hint: '"I want something that feels like a garden at midnight. Mysterious, dark, beautiful."',
    requiredVibes: [VibeTag.mystical, VibeTag.exotic, VibeTag.bold],
    minFlowers: 6, maxFlowers: 10, basePayment: 72,
  ),
  BouquetOrder(
    id: 'o75',
    customer: customerPool[8],
    description: 'Celebrity Wedding',
    hint: '"Can\'t say who. You\'d know the name. It needs to be extraordinary. I cannot stress this enough."',
    requiredVibes: [VibeTag.luxurious, VibeTag.exotic, VibeTag.romantic],
    minFlowers: 8, maxFlowers: 14, basePayment: 110,
  ),
];

// ── Premium landmark orders — Days 15–30 ──────────────────────────────────────

final List<BouquetOrder> _premiumOrders = [
  BouquetOrder(
    id: 'o76',
    customer: customerPool[17],
    description: 'Opera House Opening Night',
    hint: '"Opening night at the opera. Six hundred people. The flowers must be talked about for years."',
    requiredVibes: [VibeTag.luxurious, VibeTag.bold, VibeTag.elegant],
    minFlowers: 9, maxFlowers: 16, basePayment: 120,
  ),
  BouquetOrder(
    id: 'o77',
    customer: customerPool[14],
    description: 'State Dinner',
    hint: '"Classified. All I can say is: heads of state. Multiple. Do not let me down."',
    requiredVibes: [VibeTag.luxurious, VibeTag.traditional, VibeTag.elegant],
    minFlowers: 8, maxFlowers: 14, basePayment: 115,
  ),
  BouquetOrder(
    id: 'o78',
    customer: customerPool[0],
    description: 'International Art Fair',
    hint: '"I\'m exhibiting at Art Basel. The collectors need to remember my stand. Wild, brave, unforgettable."',
    requiredVibes: [VibeTag.exotic, VibeTag.bold, VibeTag.mystical],
    minFlowers: 8, maxFlowers: 14, basePayment: 110,
  ),
  BouquetOrder(
    id: 'o79',
    customer: customerPool[7],
    description: 'Diamond Anniversary',
    hint: '"Sixty years married. Every flower should hold sixty years of love."',
    requiredVibes: [VibeTag.romantic, VibeTag.luxurious, VibeTag.traditional],
    minFlowers: 8, maxFlowers: 14, basePayment: 105,
  ),
  BouquetOrder(
    id: 'o80',
    customer: customerPool[9],
    description: 'Destination Wedding Arch',
    hint: '"Beach ceremony at sunset. The arch needs to look like it belongs to the ocean."',
    requiredVibes: [VibeTag.exotic, VibeTag.romantic, VibeTag.natural],
    minFlowers: 9, maxFlowers: 16, basePayment: 115,
    prefersGreens: true,
  ),
  BouquetOrder(
    id: 'o81',
    customer: customerPool[5],
    description: 'Product Launch Event',
    hint: '"Luxury car brand. Budget: unlimited. Brief: make people feel rich just walking in."',
    requiredVibes: [VibeTag.luxurious, VibeTag.bold, VibeTag.exotic],
    minFlowers: 8, maxFlowers: 14, basePayment: 110,
  ),
  BouquetOrder(
    id: 'o82',
    customer: customerPool[16],
    description: 'Royal Garden Party',
    hint: '"Actual garden party at an actual estate. The host is an actual lord. No pressure."',
    requiredVibes: [VibeTag.elegant, VibeTag.traditional, VibeTag.luxurious],
    minFlowers: 8, maxFlowers: 14, basePayment: 108,
  ),
  BouquetOrder(
    id: 'o83',
    customer: customerPool[11],
    description: 'End-of-Year Gala',
    hint: '"The company has had its best year ever. This party is a thank you. Make it legendary."',
    requiredVibes: [VibeTag.festive, VibeTag.luxurious, VibeTag.vibrant],
    minFlowers: 8, maxFlowers: 14, basePayment: 105,
  ),
  BouquetOrder(
    id: 'o84',
    customer: customerPool[13],
    description: 'Spiritual Sanctuary',
    hint: '"We\'re building a healing sanctuary. Every room needs flowers. Start with the meditation hall."',
    requiredVibes: [VibeTag.mystical, VibeTag.soft, VibeTag.natural],
    minFlowers: 7, maxFlowers: 12, basePayment: 95,
  ),
  BouquetOrder(
    id: 'o85',
    customer: customerPool[18],
    description: 'Legendary Farewell',
    hint: '"The greatest teacher this city has ever had is retiring. The whole town is coming to say goodbye."',
    requiredVibes: [VibeTag.elegant, VibeTag.cheerful, VibeTag.traditional],
    minFlowers: 8, maxFlowers: 14, basePayment: 100,
  ),
];

// ── All pools merged for convenience ──────────────────────────────────────────

final List<BouquetOrder> orderPool = [
  ..._earlyOrders,
  ..._midOrders,
  ..._lateOrders,
];

// ── Mystery orders ─────────────────────────────────────────────────────────────

final _mysteryCustomer = const CustomerProfile(
  id: 'mystery',
  name: 'Unknown',
  portrait: '🎭',
  mood: CustomerMood.neutral,
);

final List<BouquetOrder> mysteryOrderPool = [
  BouquetOrder(
    id: 'm1',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"No instructions. No hints. Surprise me — I trust your instincts completely."',
    requiredVibes: [], minFlowers: 4, maxFlowers: 9, basePayment: 70, isMystery: true,
  ),
  BouquetOrder(
    id: 'm2',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"I want something I\'ve never seen before. Use your imagination — I\'ll know if you played it safe."',
    requiredVibes: [], minFlowers: 4, maxFlowers: 9, basePayment: 75, isMystery: true,
  ),
  BouquetOrder(
    id: 'm3',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"Anonymous. Urgent. Make it memorable — the person who receives this will never forget it."',
    requiredVibes: [], minFlowers: 5, maxFlowers: 10, basePayment: 80, isMystery: true,
  ),
  BouquetOrder(
    id: 'm4',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"I\'m a collector of beautiful things. Show me what you\'re really capable of."',
    requiredVibes: [], minFlowers: 4, maxFlowers: 9, basePayment: 72, isMystery: true,
  ),
  BouquetOrder(
    id: 'm5',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"My therapist said I need more beauty in my life. No pressure."',
    requiredVibes: [], minFlowers: 3, maxFlowers: 8, basePayment: 65, isMystery: true,
  ),
  BouquetOrder(
    id: 'm6',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"A gift from one artist to another. You\'ll understand when they receive it."',
    requiredVibes: [], minFlowers: 5, maxFlowers: 10, basePayment: 78, isMystery: true,
  ),
  BouquetOrder(
    id: 'm7',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"I write the orders down and burn the paper. Just make something extraordinary."',
    requiredVibes: [], minFlowers: 5, maxFlowers: 10, basePayment: 82, isMystery: true,
  ),
  BouquetOrder(
    id: 'm8',
    customer: _mysteryCustomer,
    description: 'Premium Mystery',
    hint: '"Every week I challenge a different florist. You\'re the last one left. Don\'t disappoint."',
    requiredVibes: [], minFlowers: 6, maxFlowers: 12, basePayment: 90, isMystery: true,
  ),
];

// ── Day-tiered order generation ────────────────────────────────────────────────
//
// Days  1–4:  only early orders (simple vibes, small bunches)
// Days  5–10: early + mid orders blended
// Days 11–18: early + mid + late orders (premium unlocked)
// Days 19–30: all tiers, with premium orders weighted heavily + mystery every 3 days

/// Number of customers that arrive on [day], before any upgrade bonuses.
/// Scales from 3 (day 1) to 8 (day 6+), then to 10 (day 15+).
int ordersOnDay(int day) =>
    day >= 15 ? 3 + (day - 1).clamp(0, 7) : 3 + (day - 1).clamp(0, 5);

/// Average minimum stems across the orders that can appear on [day].
///
/// Mirrors the pool construction in [generateDayOrders], so an estimate built
/// on it stays true as tiers unlock. Used to answer "how many days does my
/// stock cover?" in the market.
double averageMinStems(int day) {
  final pool = <BouquetOrder>[..._earlyOrders];
  if (day >= 3) pool.addAll(_midOrders);
  if (day >= 8) pool.addAll(_lateOrders);
  if (day >= 15) pool.addAll(_premiumOrders);
  if (pool.isEmpty) return 4;
  return pool.fold<int>(0, (sum, o) => sum + o.minFlowers) / pool.length;
}

/// [extraOrders] adds bonus customers (e.g. from the Display Window upgrade).
List<BouquetOrder> generateDayOrders(int day, {int extraOrders = 0}) {
  var count = ordersOnDay(day);
  count += extraOrders;

  // Build a pool weighted by day progress
  final List<BouquetOrder> pool = [];

  // Early orders always available
  pool.addAll(_earlyOrders);

  // Mid orders unlock on day 3
  if (day >= 3) pool.addAll(_midOrders);

  // Late orders unlock on day 8
  if (day >= 8) pool.addAll(_lateOrders);

  // Premium landmark orders unlock on day 15
  if (day >= 15) pool.addAll(_premiumOrders);

  // Shuffle and take
  final shuffled = List<BouquetOrder>.from(pool)..shuffle();
  final orders = shuffled.take(count).toList();

  // Inject mystery orders:
  //  - Days  4–18: every 4 days
  //  - Days 19–30: every 3 days (more frequent late game)
  final mysteryInterval = day >= 19 ? 3 : 4;
  if (day >= 4 && day % mysteryInterval == 0) {
    final mysteryIdx = (day ~/ mysteryInterval - 1) % mysteryOrderPool.length;
    final insertAt = (orders.length / 2).round().clamp(1, orders.length);
    orders.insert(insertAt, mysteryOrderPool[mysteryIdx]);
  }

  return orders;
}

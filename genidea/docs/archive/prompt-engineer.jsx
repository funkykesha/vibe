import { useState, useEffect, useRef } from "react";

// ── Data ──────────────────────────────────────────────────────────────────────

const TASK_CATEGORIES = [
  { id: "writing",    label: "Написание текста", icon: "✍️",  desc: "Статьи, письма, посты, эссе" },
  { id: "analysis",  label: "Анализ",            icon: "🔬",  desc: "Данные, документы, исследования" },
  { id: "code",      label: "Код",               icon: "⌨️",  desc: "Разработка, дебаггинг, рефакторинг" },
  { id: "brainstorm",label: "Брейншторм",        icon: "💡",  desc: "Идеи, концепции, решения" },
  { id: "review",    label: "Review",            icon: "🔍",  desc: "Проверка документов, кода, текстов" },
  { id: "research",  label: "Исследование",      icon: "📚",  desc: "Поиск, синтез, структуризация знаний" },
  { id: "planning",  label: "Планирование",      icon: "🗂️",  desc: "Проекты, задачи, стратегии" },
  { id: "custom",    label: "Своя задача",       icon: "⚙️",  desc: "Нестандартный запрос" },
];

const STATIC_QUESTIONS = {
  writing: [
    { q: "Что именно нужно написать?", placeholder: "Статья, пост, письмо, описание продукта..." },
    { q: "Для кого пишем?", placeholder: "Целевая аудитория, площадка, контекст публикации" },
    { q: "Какой тон и стиль?", placeholder: "Формальный / дружелюбный / экспертный / продающий..." },
    { q: "Какой объём и формат?", placeholder: "Примерный объём, структура, наличие заголовков" },
    { q: "Что должен почувствовать или сделать читатель?", placeholder: "Купить, поверить, понять, поделиться..." },
  ],
  analysis: [
    { q: "Что анализируем?", placeholder: "Тип данных, документ, явление, набор метрик..." },
    { q: "Какой вопрос хотим ответить?", placeholder: "Что ищем, какую гипотезу проверяем" },
    { q: "В каком формате нужен результат?", placeholder: "Таблица, summary, выводы, рекомендации..." },
    { q: "Есть ли ограничения или угол зрения?", placeholder: "Только определённый период, срез, методология" },
    { q: "Кто будет использовать результат?", placeholder: "Сам, команда, менеджмент, клиент..." },
  ],
  code: [
    { q: "Что нужно сделать?", placeholder: "Написать, отладить, отрефакторить, объяснить..." },
    { q: "Язык и стек?", placeholder: "Python / TypeScript / Go, фреймворки, библиотеки" },
    { q: "Какой контекст системы?", placeholder: "Архитектура, окружение, зависимости, ограничения" },
    { q: "Какой ожидаемый результат?", placeholder: "Рабочий код, объяснение, PR-описание, тесты" },
    { q: "Есть ли требования к стилю или подходу?", placeholder: "Паттерны, код-стайл, производительность, readability" },
  ],
  brainstorm: [
    { q: "Что хотим придумать?", placeholder: "Название, фичи, концепции, решения проблемы..." },
    { q: "Какие ограничения есть?", placeholder: "Бюджет, сроки, технологии, рынок" },
    { q: "Что уже пробовали или отбросили?", placeholder: "Идеи, которые не подошли и почему" },
    { q: "Сколько вариантов нужно?", placeholder: "5 идей, 20 названий, несколько концепций..." },
    { q: "По каким критериям оценивать?", placeholder: "Оригинальность, реализуемость, вау-эффект..." },
  ],
  review: [
    { q: "Что именно нужно проверить?", placeholder: "Код, текст, документ, дизайн, логика..." },
    { q: "На что делаем акцент?", placeholder: "Ошибки, стиль, логика, соответствие требованиям" },
    { q: "Какой уровень детализации нужен?", placeholder: "Поверхностно / глубоко, построчно / по смыслу" },
    { q: "Что считать «хорошим» результатом?", placeholder: "Критерии качества, стандарты, требования" },
    { q: "Что делать с замечаниями?", placeholder: "Список, inline-комментарии, исправленная версия" },
  ],
  research: [
    { q: "Что исследуем?", placeholder: "Тема, вопрос, область знаний" },
    { q: "Какая глубина нужна?", placeholder: "Обзор / погружение, академический / прикладной уровень" },
    { q: "Какие источники приоритетны?", placeholder: "Академические, отраслевые, новостные, конкретные сайты" },
    { q: "В каком формате нужен результат?", placeholder: "Резюме, структурированный обзор, сравнение, список фактов" },
    { q: "Для чего используем?", placeholder: "Принять решение, написать статью, подготовиться к встрече..." },
  ],
  planning: [
    { q: "Что планируем?", placeholder: "Проект, задача, мероприятие, стратегия..." },
    { q: "Какие ресурсы и ограничения?", placeholder: "Время, люди, бюджет, инструменты" },
    { q: "Каков желаемый результат?", placeholder: "Конкретный outcome, метрика успеха" },
    { q: "Какие риски или зависимости есть?", placeholder: "Внешние факторы, узкие места, неопределённости" },
    { q: "В каком формате нужен план?", placeholder: "Дорожная карта, таблица, список шагов, Gantt..." },
  ],
  custom: [
    { q: "Опишите задачу своими словами", placeholder: "Что именно нужно сделать" },
    { q: "Какой результат считать успехом?", placeholder: "Конкретный outcome или артефакт" },
    { q: "Есть ли ограничения или требования?", placeholder: "Формат, объём, стиль, технические ограничения" },
    { q: "Для кого или для чего это?", placeholder: "Аудитория, цель, контекст использования" },
    { q: "Что точно не нужно делать?", placeholder: "Исключения, антипаттерны, нежелательные подходы" },
  ],
};

const TONE_CHIPS = ["Формальный", "Дружелюбный", "Экспертный", "Продающий", "Нейтральный", "Ироничный"];

const FORMAT_HINTS = {
  writing:   "Статья с 3 разделами / Пост до 300 слов / Письмо с призывом к действию",
  analysis:  "Таблица + выводы / Резюме в 5 пунктах / Полный аналитический отчёт",
  code:      "Готовая функция + тесты / Только псевдокод / С комментариями на русском",
  brainstorm:"10 идей списком / 3 концепции с описанием / Матрица плюсов и минусов",
  review:    "Список замечаний / Inline-комментарии / Оценка + рекомендации",
  research:  "Структурированный обзор / Список фактов / Резюме + ключевые выводы",
  planning:  "Дорожная карта / Таблица задач с дедлайнами / Пошаговый список",
  custom:    "Список / Таблица / Свободный текст",
};

const TRANSFORM_OPTIONS = [
  { id: "xml",      label: "Добавить XML-структуру", icon: "📋" },
  { id: "compress", label: "Сжать / упростить",      icon: "🗜️" },
  { id: "tone",     label: "Сменить тон/стиль",      icon: "🎯" },
  { id: "detailed", label: "Улучшить детализацию",   icon: "✨" },
];

// ── Themes ────────────────────────────────────────────────────────────────────

const DARK = {
  bg:           "#09090e",
  surface:      "rgba(255,255,255,0.015)",
  surface2:     "rgba(255,255,255,0.025)",
  border:       "#1e1e2e",
  text:         "#e0e0f0",
  textMuted:    "#7070a0",
  textDim:      "#505075",
  accent:       "#6b5ce7",
  accentHover:  "#7d6ef0",
  accentSoft:   "rgba(107,92,231,0.08)",
  grid:         "rgba(90,80,180,0.03)",
  glow:         "rgba(70,50,160,0.09)",
  chip:         "rgba(107,92,231,0.06)",
  chipBorder:   "#2a2a42",
  spinnerTrack: "#181825",
  placeholder:  "#555575",
  successBg:    "rgba(40,100,40,0.1)",
  successBorder:"#1e3a1e",
  successText:  "#4a9a4a",
};

const LIGHT = {
  bg:           "#fdf6ee",
  surface:      "#ffffff",
  surface2:     "#fff5e8",
  border:       "#e8c9a0",
  text:         "#1e1410",
  textMuted:    "#7a5840",
  textDim:      "#a07850",
  accent:       "#c84b1a",
  accentHover:  "#e05520",
  accentSoft:   "rgba(200,75,26,0.09)",
  grid:         "rgba(160,90,30,0.04)",
  glow:         "rgba(180,90,20,0.07)",
  chip:         "rgba(200,75,26,0.07)",
  chipBorder:   "#e8c9a0",
  spinnerTrack: "#e8c9a0",
  placeholder:  "#c0966a",
  successBg:    "rgba(30,90,30,0.08)",
  successBorder:"#88aa88",
  successText:  "#3a7a3a",
};

// ── Prompt builders ───────────────────────────────────────────────────────────

const buildGenerationPrompt = (category, context, questions, answers) => {
  const qa = questions.map(({ q }, i) =>
    `Q: ${q}\nA: ${answers[i]?.trim() || "(не указано)"}`
  ).join("\n\n");
  return `You are an elite prompt engineer. Craft a comprehensive, highly-optimized prompt for a powerful AI model (Claude Opus or GPT-4 level).

Task category: ${category.label} — ${category.desc}
${context.trim() ? `\nUser background / existing context:\n"""\n${context.trim()}\n"""\n` : ""}
User's answers:
${qa}

Write a structured prompt in Russian that includes:
1. Role/persona for the AI
2. Context and background (weave in the user's background naturally)
3. Specific task with all requirements
4. Output format (structure, length, style)
5. Constraints and things to avoid

Return ONLY the final prompt text. No preamble, no "Here is your prompt:", no markdown fences.`;
};

const buildRefinementPrompt = (existingPrompt, refinement) =>
  `You are an elite prompt engineer. Here is a prompt you previously wrote:\n\n"""\n${existingPrompt}\n"""\n\nThe user wants to refine it:\n"${refinement}"\n\nRewrite the prompt incorporating this feedback. Keep everything else intact.\nReturn ONLY the revised prompt text, no preamble.`;

const buildTransformPrompt = (originalPrompt, selectedIds, customText) => {
  const LABELS = {
    xml:      "Add XML structure: wrap semantic sections in <role>, <context>, <task>, <format>, <constraints> tags",
    compress: "Compress and simplify — remove redundancy, make it shorter without losing meaning",
    tone:     "Improve tone and style — make it more professional, precise, and authoritative",
    detailed: "Improve detail and specificity — add more context, examples, and explicit requirements",
  };
  const instructions = [...selectedIds.map(id => LABELS[id]).filter(Boolean)];
  if (customText.trim()) instructions.push(customText.trim());
  return `You are an expert prompt engineer. Transform this prompt:\n\n"""\n${originalPrompt}\n"""\n\nApply these improvements:\n${instructions.map(i => `- ${i}`).join("\n")}\n\nReturn ONLY the transformed prompt, no explanation, no preamble.`;
};

const buildTranslatePrompt = (promptText) =>
  `Translate the following prompt to English. Keep the exact same structure, formatting, tone, and meaning. Return ONLY the translated text, no preamble.\n\n"""\n${promptText}\n"""`;

// ── API ───────────────────────────────────────────────────────────────────────

const callClaude = async (systemMessage, userMessage) => {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1000,
      system: systemMessage,
      messages: [{ role: "user", content: userMessage }],
    }),
  });
  const data = await res.json();
  return data.content?.[0]?.text || "";
};

// ── Hooks ─────────────────────────────────────────────────────────────────────

const useTypewriter = (text, speed = 5) => {
  const [displayed, setDisplayed] = useState("");
  const [done, setDone] = useState(false);
  useEffect(() => {
    setDisplayed(""); setDone(false);
    if (!text) return;
    let i = 0;
    const iv = setInterval(() => {
      i++;
      setDisplayed(text.slice(0, i));
      if (i >= text.length) { clearInterval(iv); setDone(true); }
    }, speed);
    return () => clearInterval(iv);
  }, [text]);
  return { displayed, done };
};

// ── App ───────────────────────────────────────────────────────────────────────

export default function App() {
  const [theme, setTheme]           = useState("dark");
  const T = theme === "dark" ? DARK : LIGHT;

  // step: -1=mode  0=category(A)  1=context(A)  2=questions(A)  10=B1  11=B2b  3=result(A+B)
  const [step, setStep]             = useState(-1);
  const [branch, setBranch]         = useState(null);

  // Branch A
  const [category, setCategory]     = useState(null);
  const [context, setContext]       = useState("");
  const [answers, setAnswers]       = useState(Array(5).fill(""));
  const [activeQ, setActiveQ]       = useState(0);
  const refs = useRef([]);

  // Branch B
  const [branchBPrompt, setBranchBPrompt] = useState("");
  const [selectedTransforms, setSelectedTransforms] = useState([]);
  const [customTransform, setCustomTransform] = useState("");

  // Result (shared)
  const [prompt, setPrompt]         = useState("");
  const [refinement, setRefinement] = useState("");
  const [refineOpen, setRefineOpen] = useState(false);
  const [loading, setLoading]       = useState(false);
  const [copied, setCopied]         = useState(false);
  const [translating, setTranslating] = useState(false);
  const [translated, setTranslated] = useState(false);

  const questions   = category ? STATIC_QUESTIONS[category.id] : [];
  const filled      = answers.filter(a => a.trim()).length;
  const canGenerate = filled >= 3;
  const canTransform = selectedTransforms.length > 0 || customTransform.trim().length > 0;

  const { displayed: typedPrompt, done: typingDone } = useTypewriter(prompt);

  // ── Actions ───────────────────────────────────────────────────────────────────

  const selectBranch = (b) => { setBranch(b); setStep(b === "A" ? 0 : 10); };
  const selectCategory = (cat) => { setCategory(cat); setStep(1); };
  const goToQuestions = () => { setAnswers(Array(5).fill("")); setStep(2); };

  const resetResult = () => { setPrompt(""); setRefineOpen(false); setRefinement(""); setTranslated(false); };

  const generate = async () => {
    setStep(3); setLoading(true); resetResult();
    const result = await callClaude(buildGenerationPrompt(category, context, questions, answers), "Generate the prompt now.")
      .catch(() => "Ошибка генерации. Попробуйте ещё раз.");
    setPrompt(result); setLoading(false);
  };

  const transform = async () => {
    setStep(3); setLoading(true); resetResult();
    const result = await callClaude(buildTransformPrompt(branchBPrompt, selectedTransforms, customTransform), "Transform the prompt now.")
      .catch(() => "Ошибка преобразования. Попробуйте ещё раз.");
    setPrompt(result); setLoading(false);
  };

  const refine = async () => {
    if (!refinement.trim()) return;
    setLoading(true); setPrompt(""); setTranslated(false);
    const result = await callClaude(buildRefinementPrompt(prompt, refinement), "Refine the prompt now.")
      .catch(() => "Ошибка. Попробуйте ещё раз.");
    setPrompt(result); setLoading(false); setRefineOpen(false); setRefinement("");
  };

  const translateToEn = async () => {
    setTranslating(true);
    const result = await callClaude(buildTranslatePrompt(prompt), "Translate now.")
      .catch(() => null);
    if (result) { setPrompt(result); setTranslated(true); }
    setTranslating(false);
  };

  const copy = () => {
    navigator.clipboard.writeText(prompt);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const reset = () => {
    setStep(-1); setBranch(null); setCategory(null); setContext("");
    setAnswers(Array(5).fill("")); setActiveQ(0);
    setBranchBPrompt(""); setSelectedTransforms([]); setCustomTransform("");
    resetResult();
  };

  const toggleTransform = (id) =>
    setSelectedTransforms(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);

  const addToneChip = (chip, qIndex) => {
    const a = [...answers];
    a[qIndex] = a[qIndex].trim() ? a[qIndex].trim() + ", " + chip : chip;
    setAnswers(a);
  };

  // ── UI helpers ────────────────────────────────────────────────────────────────

  const STEP_LABELS_A = ["Задача", "Контекст", "Вопросы", "Промпт"];
  const STEP_LABELS_B = ["Промпт", "Трансформация", "Результат"];

  const sectionLabel = (txt) => (
    <p style={{ color: T.textDim, fontSize: "11px", letterSpacing: "0.13em", marginBottom: "18px", textTransform: "uppercase" }}>
      // {txt}
    </p>
  );

  const primaryBtn = (disabled = false) => ({
    fontFamily: "inherit",
    cursor: disabled ? "not-allowed" : "pointer",
    borderRadius: "6px",
    fontSize: "13px",
    transition: "all 0.15s",
    background: disabled ? (theme === "dark" ? "#0f0f1a" : "#e0c8b0") : T.accent,
    border: "none",
    padding: "11px 20px",
    color: disabled ? T.textDim : "#fff",
    letterSpacing: "0.04em",
  });

  const ghostBtn = (color) => ({
    fontFamily: "inherit", cursor: "pointer", borderRadius: "6px", fontSize: "12px",
    transition: "all 0.15s", background: "transparent", border: `1px solid ${T.border}`,
    padding: "10px 15px", color: color || T.textMuted,
  });

  const CatHeader = () => category && (
    <div style={{ display: "flex", alignItems: "center", gap: "9px", marginBottom: "22px" }}>
      <span style={{ fontSize: "17px" }}>{category.icon}</span>
      <span style={{ fontSize: "12px", color: T.accent, letterSpacing: "0.04em" }}>{category.label}</span>
    </div>
  );

  const FieldTextarea = ({ value, onChange, placeholder, rows = 3, autoFocus = false, onKeyDown }) => (
    <textarea
      autoFocus={autoFocus}
      value={value}
      onChange={onChange}
      onKeyDown={onKeyDown}
      placeholder={placeholder}
      rows={rows}
      style={{
        width: "100%", background: T.surface2, border: `1px solid ${T.border}`,
        borderRadius: "6px", color: T.text, padding: "10px 13px", fontSize: "13px",
        fontFamily: "inherit", resize: "vertical", outline: "none",
        boxSizing: "border-box", lineHeight: "1.6", transition: "border-color 0.2s",
      }}
      onFocus={e => e.target.style.borderColor = T.accent}
      onBlur={e => e.target.style.borderColor = T.border}
    />
  );

  const Spinner = ({ msg }) => (
    <div style={{ textAlign: "center", padding: "60px 0" }}>
      <div style={{ width: "34px", height: "34px", margin: "0 auto 16px", border: `2px solid ${T.spinnerTrack}`, borderTop: `2px solid ${T.accent}`, borderRadius: "50%", animation: "spin 0.9s linear infinite" }} />
      <p style={{ color: T.textDim, fontSize: "12px", letterSpacing: "0.1em" }}>{msg}</p>
    </div>
  );

  // ── Render ────────────────────────────────────────────────────────────────────

  return (
    <div style={{ minHeight: "100vh", background: T.bg, color: T.text, fontFamily: "'Courier New', monospace", margin: 0, padding: 0, transition: "background 0.3s, color 0.3s" }}>

      {/* grid */}
      <div style={{ position: "fixed", inset: 0, zIndex: 0, pointerEvents: "none",
        backgroundImage: `linear-gradient(${T.grid} 1px,transparent 1px),linear-gradient(90deg,${T.grid} 1px,transparent 1px)`,
        backgroundSize: "40px 40px" }} />
      {/* glow */}
      <div style={{ position: "fixed", top: "-15%", left: "50%", transform: "translateX(-50%)", width: "700px", height: "500px",
        background: `radial-gradient(ellipse,${T.glow} 0%,transparent 65%)`, pointerEvents: "none", zIndex: 0 }} />

      <div style={{ position: "relative", zIndex: 1, maxWidth: "720px", margin: "0 auto", padding: "44px 22px 80px" }}>

        {/* ── Header ── */}
        <div style={{ marginBottom: "44px", display: "flex", alignItems: "flex-start", justifyContent: "space-between" }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "9px", marginBottom: "7px" }}>
              <div style={{ width: "6px", height: "6px", borderRadius: "50%", background: T.accent, boxShadow: `0 0 8px ${T.accent}`, animation: "pulse 2s infinite" }} />
              <span style={{ fontSize: "10px", letterSpacing: "0.2em", color: T.accent, textTransform: "uppercase" }}>Prompt Engineer</span>
            </div>
            <h1 style={{ fontSize: "clamp(19px,3.5vw,28px)", fontWeight: "normal", letterSpacing: "-0.02em", margin: "0 0 5px", color: T.text }}>
              Генератор промптов
            </h1>
            <p style={{ color: T.textDim, fontSize: "12px", margin: 0 }}>Опиши задачу — получи промпт для мощной модели</p>
          </div>
          <button onClick={() => setTheme(t => t === "dark" ? "light" : "dark")}
            style={{ fontFamily: "inherit", cursor: "pointer", background: T.surface2, border: `1px solid ${T.border}`, borderRadius: "20px", padding: "6px 12px", fontSize: "12px", color: T.textMuted, marginTop: "4px", transition: "all 0.2s", whiteSpace: "nowrap" }}>
            {theme === "dark" ? "☀️ Light" : "🌙 Dark"}
          </button>
        </div>

        {/* ── Step indicator — Branch A ── */}
        {step >= 0 && step <= 3 && branch === "A" && (
          <div style={{ display: "flex", alignItems: "center", gap: "5px", marginBottom: "36px", flexWrap: "wrap" }}>
            {STEP_LABELS_A.map((label, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: "5px" }}>
                <div style={{ opacity: i <= step ? 1 : 0.2, display: "flex", alignItems: "center", gap: "5px" }}>
                  <div style={{
                    width: "18px", height: "18px", borderRadius: "50%", fontSize: "9px",
                    display: "flex", alignItems: "center", justifyContent: "center",
                    border: `1px solid ${T.accent}`, background: i < step ? T.accent : "transparent",
                    color: i < step ? "#fff" : T.accent,
                  }}>
                    {i < step ? "✓" : i + 1}
                  </div>
                  <span style={{ fontSize: "11px", color: i <= step ? T.textMuted : T.border, letterSpacing: "0.04em" }}>{label}</span>
                </div>
                {i < 3 && <div style={{ width: "18px", height: "1px", background: i < step ? T.accent : T.border }} />}
              </div>
            ))}
          </div>
        )}

        {/* ── Step indicator — Branch B ── */}
        {(step === 10 || step === 11 || (step === 3 && branch === "B")) && (
          <div style={{ display: "flex", alignItems: "center", gap: "5px", marginBottom: "36px" }}>
            {STEP_LABELS_B.map((label, i) => {
              const isDone   = (i === 0 && (step === 11 || step === 3)) || (i === 1 && step === 3);
              const isActive = (i === 0 && step === 10) || (i === 1 && step === 11) || (i === 2 && step === 3);
              return (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: "5px" }}>
                  <div style={{ opacity: isActive || isDone ? 1 : 0.2, display: "flex", alignItems: "center", gap: "5px" }}>
                    <div style={{
                      width: "18px", height: "18px", borderRadius: "50%", fontSize: "9px",
                      display: "flex", alignItems: "center", justifyContent: "center",
                      border: `1px solid ${T.accent}`, background: isDone ? T.accent : "transparent",
                      color: isDone ? "#fff" : T.accent,
                    }}>{isDone ? "✓" : i + 1}</div>
                    <span style={{ fontSize: "11px", color: isActive || isDone ? T.textMuted : T.border }}>{label}</span>
                  </div>
                  {i < 2 && <div style={{ width: "18px", height: "1px", background: isDone ? T.accent : T.border }} />}
                </div>
              );
            })}
          </div>
        )}

        {/* ── STEP -1: mode screen ─────────────────────────────────────────── */}
        {step === -1 && (
          <>
            {sectionLabel("что хотите сделать?")}
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px" }}>
              {[
                { b: "A", icon: "✦", title: "Создать промпт", desc: "Опишите задачу — соберём оптимальный промпт шаг за шагом" },
                { b: "B", icon: "↺", title: "Улучшить промпт", desc: "Вставьте готовый промпт — трансформируем или переведём" },
              ].map(({ b, icon, title, desc }) => (
                <button key={b} onClick={() => selectBranch(b)}
                  style={{ fontFamily: "inherit", cursor: "pointer", borderRadius: "10px", transition: "all 0.18s", background: T.surface, border: `1px solid ${T.border}`, padding: "24px 20px", textAlign: "left", color: T.text }}
                  onMouseEnter={e => { e.currentTarget.style.borderColor = T.accent; e.currentTarget.style.background = T.accentSoft; }}
                  onMouseLeave={e => { e.currentTarget.style.borderColor = T.border; e.currentTarget.style.background = T.surface; }}
                >
                  <div style={{ fontSize: "22px", marginBottom: "10px", color: T.accent }}>{icon}</div>
                  <div style={{ fontSize: "14px", fontWeight: 600, marginBottom: "6px", color: T.text }}>{title}</div>
                  <div style={{ fontSize: "12px", color: T.textMuted, lineHeight: "1.5" }}>{desc}</div>
                </button>
              ))}
            </div>
          </>
        )}

        {/* ── STEP 0: category ─────────────────────────────────────────────── */}
        {step === 0 && (
          <>
            {sectionLabel("выберите тип задачи")}
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(180px,1fr))", gap: "9px" }}>
              {TASK_CATEGORIES.map(cat => (
                <button key={cat.id} onClick={() => selectCategory(cat)}
                  style={{ fontFamily: "inherit", cursor: "pointer", borderRadius: "7px", transition: "all 0.15s", background: T.surface, border: `1px solid ${T.border}`, padding: "16px 14px", textAlign: "left", color: T.text }}
                  onMouseEnter={e => { e.currentTarget.style.borderColor = T.accent; e.currentTarget.style.background = T.accentSoft; }}
                  onMouseLeave={e => { e.currentTarget.style.borderColor = T.border; e.currentTarget.style.background = T.surface; }}
                >
                  <div style={{ fontSize: "19px", marginBottom: "6px" }}>{cat.icon}</div>
                  <div style={{ fontSize: "13px", fontWeight: 600, marginBottom: "3px", color: T.text }}>{cat.label}</div>
                  <div style={{ fontSize: "11px", color: T.textMuted, lineHeight: "1.4" }}>{cat.desc}</div>
                </button>
              ))}
            </div>
            <div style={{ marginTop: "16px" }}>
              <button onClick={() => setStep(-1)} style={ghostBtn()}>← Назад</button>
            </div>
          </>
        )}

        {/* ── STEP 1: context ──────────────────────────────────────────────── */}
        {step === 1 && (
          <>
            <CatHeader />
            {sectionLabel("бэкграунд и контекст")}
            <p style={{ color: T.textMuted, fontSize: "12px", lineHeight: "1.7", marginBottom: "16px" }}>
              Что уже есть — наработки, данные, стек, ограничения.
              <br /><span style={{ color: T.textDim }}>Необязательно — но чем больше контекста, тем точнее промпт.</span>
            </p>
            <FieldTextarea
              autoFocus
              value={context}
              onChange={e => setContext(e.target.value)}
              rows={7}
              placeholder={"Например:\n— Пишу диплом по полимерным плёнкам, есть литобзор и эксперимент\n— Стек: Python + FastAPI + PostgreSQL\n— Научрук хочет акцент на практическом применении\n— Оформление по ГОСТ 7.32"}
            />
            <div style={{ display: "flex", gap: "9px", marginTop: "16px", alignItems: "center" }}>
              <button onClick={goToQuestions} style={primaryBtn()}>Далее →</button>
              <button onClick={() => setStep(0)} style={ghostBtn()}>← Тип задачи</button>
            </div>
          </>
        )}

        {/* ── STEP 2: questions ─────────────────────────────────────────────── */}
        {step === 2 && (
          <>
            <CatHeader />
            {context.trim() && (
              <div style={{ display: "flex", gap: "8px", background: T.accentSoft, border: `1px solid ${T.border}`, borderRadius: "6px", padding: "8px 12px", marginBottom: "20px" }}>
                <span style={{ fontSize: "9px", color: T.accent, letterSpacing: "0.12em", whiteSpace: "nowrap", marginTop: "2px" }}>КОНТЕКСТ</span>
                <p style={{ margin: 0, fontSize: "11px", color: T.textMuted, lineHeight: "1.5", overflow: "hidden", display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical" }}>
                  {context}
                </p>
                <button onClick={() => setStep(1)}
                  style={{ fontFamily: "inherit", background: "transparent", border: "none", padding: "0 2px", color: T.textDim, fontSize: "11px", marginLeft: "auto", whiteSpace: "nowrap", cursor: "pointer" }}>
                  изменить
                </button>
              </div>
            )}
            {sectionLabel("уточните задачу")}
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              {questions.map(({ q, placeholder }, i) => {
                const isTone   = q.toLowerCase().includes("тон");
                const isFormat = q.toLowerCase().includes("формат") || q.toLowerCase().includes("объём");
                return (
                  <div key={i} style={{
                    borderLeft: `2px solid ${activeQ === i ? T.accent : answers[i].trim() ? T.textDim : T.border}`,
                    paddingLeft: "14px", transition: "border-color 0.2s",
                  }}>
                    <label style={{ display: "block", fontSize: "12px", color: T.textMuted, marginBottom: "6px", letterSpacing: "0.03em" }}>
                      <span style={{ color: T.accent, marginRight: "6px" }}>{String(i + 1).padStart(2, "0")}</span>
                      {q}
                    </label>
                    <textarea
                      ref={el => refs.current[i] = el}
                      value={answers[i]}
                      onFocus={() => setActiveQ(i)}
                      onChange={e => { const a = [...answers]; a[i] = e.target.value; setAnswers(a); }}
                      onKeyDown={e => {
                        if (e.key === "Tab" && !e.shiftKey && i < questions.length - 1) {
                          e.preventDefault(); refs.current[i + 1]?.focus();
                        }
                      }}
                      placeholder={placeholder}
                      rows={2}
                      style={{
                        width: "100%", background: T.surface2, border: `1px solid ${T.border}`,
                        borderRadius: "6px", color: T.text, padding: "9px 12px", fontSize: "13px",
                        fontFamily: "inherit", resize: "vertical", outline: "none",
                        boxSizing: "border-box", lineHeight: "1.55", transition: "border-color 0.2s",
                      }}
                      onFocus={e => e.target.style.borderColor = T.accent}
                      onBlur={e => e.target.style.borderColor = T.border}
                    />
                    {isTone && (
                      <div style={{ display: "flex", flexWrap: "wrap", gap: "5px", marginTop: "7px" }}>
                        {TONE_CHIPS.map(chip => (
                          <button key={chip} onClick={() => addToneChip(chip, i)}
                            style={{ fontFamily: "inherit", cursor: "pointer", borderRadius: "12px", fontSize: "11px", padding: "3px 10px", background: T.chip, border: `1px solid ${T.chipBorder}`, color: T.textMuted, transition: "all 0.15s" }}
                            onMouseEnter={e => { e.currentTarget.style.borderColor = T.accent; e.currentTarget.style.color = T.accent; }}
                            onMouseLeave={e => { e.currentTarget.style.borderColor = T.chipBorder; e.currentTarget.style.color = T.textMuted; }}
                          >
                            {chip}
                          </button>
                        ))}
                      </div>
                    )}
                    {isFormat && category && FORMAT_HINTS[category.id] && (
                      <p style={{ margin: "6px 0 0", fontSize: "11px", color: T.textDim, lineHeight: "1.5" }}>
                        Например: {FORMAT_HINTS[category.id]}
                      </p>
                    )}
                  </div>
                );
              })}
            </div>
            <div style={{ display: "flex", gap: "9px", marginTop: "26px", alignItems: "center" }}>
              <button onClick={generate} disabled={!canGenerate} style={primaryBtn(!canGenerate)}>
                Сгенерировать промпт →
              </button>
              <button onClick={() => setStep(1)} style={ghostBtn()}>← Контекст</button>
              {!canGenerate && <span style={{ fontSize: "11px", color: T.textDim }}>заполните хотя бы 3 поля</span>}
            </div>
          </>
        )}

        {/* ── STEP 10: B1 — вставка промпта ────────────────────────────────── */}
        {step === 10 && (
          <>
            {sectionLabel("вставьте ваш промпт")}
            <FieldTextarea
              autoFocus
              value={branchBPrompt}
              onChange={e => setBranchBPrompt(e.target.value)}
              rows={11}
              placeholder={"Вставьте готовый промпт — разберём, улучшим, переведём..."}
            />
            <p style={{ margin: "6px 0 0", fontSize: "11px", color: T.textDim }}>
              {branchBPrompt.length} симв.
            </p>
            <div style={{ display: "flex", gap: "9px", marginTop: "16px", flexWrap: "wrap" }}>
              <button onClick={() => setStep(11)} disabled={!branchBPrompt.trim()} style={primaryBtn(!branchBPrompt.trim())}>
                ✏️ Преобразовать →
              </button>
              <button onClick={() => setStep(-1)} style={ghostBtn()}>← Назад</button>
            </div>
          </>
        )}

        {/* ── STEP 11: B2b — карточки трансформации ────────────────────────── */}
        {step === 11 && (
          <>
            {sectionLabel("выберите трансформацию")}
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(155px,1fr))", gap: "9px", marginBottom: "24px" }}>
              {TRANSFORM_OPTIONS.map(opt => {
                const sel = selectedTransforms.includes(opt.id);
                return (
                  <button key={opt.id} onClick={() => toggleTransform(opt.id)}
                    style={{
                      fontFamily: "inherit", cursor: "pointer", borderRadius: "8px",
                      transition: "all 0.15s", padding: "16px 14px", textAlign: "left",
                      background: sel ? T.accentSoft : T.surface,
                      border: `1px solid ${sel ? T.accent : T.border}`,
                      color: sel ? T.accent : T.text,
                    }}
                    onMouseEnter={e => { if (!sel) { e.currentTarget.style.borderColor = T.accent; e.currentTarget.style.background = T.accentSoft; } }}
                    onMouseLeave={e => { if (!sel) { e.currentTarget.style.borderColor = T.border; e.currentTarget.style.background = T.surface; } }}
                  >
                    <div style={{ fontSize: "20px", marginBottom: "8px" }}>{opt.icon}</div>
                    <div style={{ fontSize: "12px", fontWeight: sel ? 600 : 400, lineHeight: "1.4" }}>{opt.label}</div>
                  </button>
                );
              })}
            </div>
            {sectionLabel("или напишите своё")}
            <FieldTextarea
              value={customTransform}
              onChange={e => setCustomTransform(e.target.value)}
              rows={3}
              placeholder={"Например: «упрости и переведи на деловой английский»\nМожно комбинировать с карточками выше"}
            />
            <div style={{ display: "flex", gap: "9px", marginTop: "16px", flexWrap: "wrap", alignItems: "center" }}>
              <button onClick={transform} disabled={!canTransform} style={primaryBtn(!canTransform)}>
                Преобразовать →
              </button>
              <button onClick={() => setStep(10)} style={ghostBtn()}>← Промпт</button>
              {!canTransform && <span style={{ fontSize: "11px", color: T.textDim }}>выберите карточку или заполните поле</span>}
            </div>
          </>
        )}

        {/* ── STEP 3: result ───────────────────────────────────────────────── */}
        {step === 3 && (
          <>
            <div style={{ display: "flex", alignItems: "center", gap: "9px", marginBottom: "20px" }}>
              {category && <span style={{ fontSize: "17px" }}>{category.icon}</span>}
              {category && <span style={{ fontSize: "12px", color: T.accent }}>{category.label}</span>}
              {translated && (
                <span style={{ fontSize: "10px", color: T.textMuted, background: T.accentSoft, border: `1px solid ${T.border}`, borderRadius: "4px", padding: "2px 8px" }}>
                  🌍 EN
                </span>
              )}
              {!loading && typingDone && (
                <span style={{ marginLeft: "auto", fontSize: "10px", color: T.successText, background: T.successBg, border: `1px solid ${T.successBorder}`, borderRadius: "4px", padding: "2px 8px" }}>
                  ✓ готово
                </span>
              )}
            </div>

            {loading ? <Spinner msg="Собираю промпт..." /> : (
              <>
                {sectionLabel("сгенерированный промпт")}
                <div style={{ background: T.surface, border: `1px solid ${T.border}`, borderRadius: "8px", padding: "20px", position: "relative", minHeight: "160px" }}>
                  <div style={{ position: "absolute", top: "10px", right: "12px", fontSize: "10px", color: T.textDim }}>
                    {prompt.length} симв.
                  </div>
                  <pre style={{ margin: 0, whiteSpace: "pre-wrap", wordBreak: "break-word", fontSize: "13px", lineHeight: "1.7", color: T.textMuted, fontFamily: "inherit" }}>
                    {typedPrompt}
                    {!typingDone && (
                      <span style={{ display: "inline-block", width: "2px", height: "13px", background: T.accent, marginLeft: "2px", verticalAlign: "text-bottom", animation: "blink 1s step-end infinite" }} />
                    )}
                  </pre>
                </div>

                <div style={{ display: "flex", gap: "9px", marginTop: "14px", flexWrap: "wrap" }}>
                  <button onClick={copy}
                    style={{ fontFamily: "inherit", cursor: "pointer", borderRadius: "6px", fontSize: "13px", transition: "all 0.15s", background: copied ? T.successBg : T.accent, border: copied ? `1px solid ${T.successBorder}` : "none", padding: "10px 18px", color: copied ? T.successText : "#fff" }}>
                    {copied ? "✓ Скопировано" : "Копировать"}
                  </button>
                  <button onClick={translateToEn} disabled={translating || translated}
                    style={{ fontFamily: "inherit", cursor: translating || translated ? "default" : "pointer", borderRadius: "6px", fontSize: "12px", transition: "all 0.15s", background: "transparent", border: `1px solid ${T.border}`, padding: "10px 14px", color: translated ? T.textDim : T.textMuted, opacity: translating ? 0.5 : 1 }}>
                    {translating ? "⏳ Перевожу..." : translated ? "🌍 Переведено" : "🌍 → EN"}
                  </button>
                  <button onClick={() => setRefineOpen(v => !v)}
                    style={{ fontFamily: "inherit", cursor: "pointer", borderRadius: "6px", fontSize: "12px", transition: "all 0.15s", background: "transparent", border: `1px solid ${refineOpen ? T.accent : T.border}`, padding: "10px 15px", color: refineOpen ? T.textMuted : T.textDim }}>
                    ✦ Уточнить
                  </button>
                  {branch === "A" && <button onClick={() => setStep(2)} style={ghostBtn()}>↺ Изменить ответы</button>}
                  {branch === "B" && <button onClick={() => setStep(11)} style={ghostBtn()}>↺ Трансформация</button>}
                  <button onClick={reset} style={ghostBtn(T.textDim)}>Новый</button>
                </div>

                {refineOpen && (
                  <div style={{ marginTop: "18px", background: T.accentSoft, border: `1px solid ${T.border}`, borderRadius: "7px", padding: "16px" }}>
                    <p style={{ margin: "0 0 10px", fontSize: "10px", color: T.textDim, letterSpacing: "0.12em", textTransform: "uppercase" }}>
                      // что уточнить?
                    </p>
                    <FieldTextarea
                      autoFocus
                      value={refinement}
                      onChange={e => setRefinement(e.target.value)}
                      rows={3}
                      placeholder={"Например:\n— Сделай тон более строгим\n— Добавь требование возвращать JSON\n— Убери упоминание аудитории"}
                    />
                    <div style={{ display: "flex", gap: "9px", marginTop: "11px" }}>
                      <button onClick={refine} disabled={!refinement.trim()} style={primaryBtn(!refinement.trim())}>
                        Применить →
                      </button>
                      <button onClick={() => setRefineOpen(false)} style={ghostBtn()}>Отмена</button>
                    </div>
                  </div>
                )}
              </>
            )}
          </>
        )}

      </div>

      <style>{`
        @keyframes spin  { to { transform: rotate(360deg); } }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
        @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0} }
        * { box-sizing: border-box; }
        textarea { color-scheme: dark; }
        textarea::placeholder { color: ${T.placeholder}; }
        button:active { transform: scale(0.97); }
      `}</style>
    </div>
  );
}

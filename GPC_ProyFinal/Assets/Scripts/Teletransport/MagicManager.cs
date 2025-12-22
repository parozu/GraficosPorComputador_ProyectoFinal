using System.Collections;
using UnityEngine;

public class MagicManager : MonoBehaviour
{
    [Header("Player (1 o 2 SkinnedMeshRenderers)")]
    [SerializeField] private SkinnedMeshRenderer skinnedA;
    [SerializeField] private SkinnedMeshRenderer skinnedB; // opcional

    [Header("Spell (MeshRenderer + GameObject)")]
    [SerializeField] private MeshRenderer spellRenderer;
    [Tooltip("Si lo dejas vacío, se moverá/activará el GameObject del spellRenderer.")]
    [SerializeField] private GameObject spellGameObject;

    [Header("Auto timings (Player)")]
    [SerializeField] private float disappearDuration = 1.0f;
    [SerializeField] private float holdGoneSeconds = 5.0f;
    [SerializeField] private float appearDuration = 1.0f;
    [SerializeField] private bool loop = false;

    [Header("Spell move")]
    [SerializeField] private float spellRiseUnits = 2.0f;
    [SerializeField] private float spellRiseDuration = 1.0f;
    [Tooltip("Tiempo que tarda en bajar al reaparecer (si 0, usa spellRiseDuration).")]
    [SerializeField] private float spellReturnDuration = 0.0f;
    [SerializeField] private bool spellMoveInLocalSpace = true;

    [Header("Spell timing")]
    [SerializeField] private bool riseAfterBlueComplete = true;

    [Header("Spell fade")]
    [Tooltip("Antes de apagar el spell, baja LineWidth / EmissiveIntensity / BlueEmissiveBoost / LightStrength a 0 en este tiempo.")]
    [SerializeField] private float spellFadeOutDuration = 0.25f;

    [Tooltip("Cuando el spell vuelve a aparecer (antes de bajar), sube de 0 a los valores originales en este tiempo.")]
    [SerializeField] private float spellFadeInDuration = 0.25f;

    [Header("Auto start")]
    [SerializeField] private bool playOnStart = true;

    private MaterialPropertyBlock _mpbPlayer;
    private MaterialPropertyBlock _mpbSpell;
    private Coroutine _sequence;

    private Vector3 _spellStartPos;
    private bool _spellPosCached;

    // Cache de valores originales del spell (por material index)
    private bool _spellOrigCached;
    private float[] _origLineWidth;
    private float[] _origEmissiveIntensity;
    private float[] _origBlueEmissiveBoost;
    private float[] _origLightStrength;

    // Player shader IDs
    static readonly int ID_AutoCycle         = Shader.PropertyToID("_AutoCycle");
    static readonly int ID_AutoStartTime     = Shader.PropertyToID("_AutoStartTime");
    static readonly int ID_DisappearDuration = Shader.PropertyToID("_DisappearDuration");
    static readonly int ID_HoldGone          = Shader.PropertyToID("_HoldGone");
    static readonly int ID_AppearDuration    = Shader.PropertyToID("_AppearDuration");
    static readonly int ID_AutoLoop          = Shader.PropertyToID("_AutoLoop");
    static readonly int ID_BoundsMinY        = Shader.PropertyToID("_BoundsMinY");
    static readonly int ID_BoundsMaxY        = Shader.PropertyToID("_BoundsMaxY");
    static readonly int ID_Disappear         = Shader.PropertyToID("_Disappear");

    // Spell shader IDs
    static readonly int ID_AnimStartTime     = Shader.PropertyToID("_AnimStartTime");
    static readonly int ID_LineWidth         = Shader.PropertyToID("_LineWidth");
    static readonly int ID_EmissiveIntensity = Shader.PropertyToID("_EmissiveIntensity");
    static readonly int ID_BlueEmissiveBoost = Shader.PropertyToID("_BlueEmissiveBoost");
    static readonly int ID_LightStrength     = Shader.PropertyToID("_LightStrength");

    void Awake()
    {
        _mpbPlayer = new MaterialPropertyBlock();
        _mpbSpell  = new MaterialPropertyBlock();
    }

    void Start()
    {
        if (playOnStart)
            PlaySequence();
    }

    /// <summary>
    /// Secuencia:
    /// 1) Activa spell, resetea posición, restaura valores originales, reinicia shader
    /// 2) Espera a emisión (o fin grow)
    /// 3) Sube spell + dispara desaparición del player
    /// 4) Al terminar de subir: fade a 0 y apaga spell
    /// 5) Al empezar la fase de aparecer del player: enciende spell arriba, anima props 0->original, baja, fade a 0 y apaga
    /// </summary>
    public void PlaySequence()
    {
        if (_sequence != null)
            StopCoroutine(_sequence);

        _sequence = StartCoroutine(CoSequence());
    }

    private IEnumerator CoSequence()
    {
        CacheSpellStartPosIfNeeded();
        CacheSpellOriginalParamsIfNeeded();

        // === Inicio spell ===
        SetSpellActive(true);
        ResetSpellToStartPos();
        RestoreSpellParamsInstant();
        StartSpellShader();

        float wait = GetSpellWaitBeforeRise();
        if (wait > 0f) yield return new WaitForSeconds(wait);

        // === Desaparición del player sincronizada con subida ===
        float playerStartTime = Time.time;
        ApplyPlayerAuto(playerStartTime);
        yield return CoMoveSpell(+spellRiseUnits, Mathf.Max(0.0001f, spellRiseDuration));

        // Fade a 0 y apagar
        yield return CoFadeSpellParamsToZero(Mathf.Max(0.0001f, spellFadeOutDuration));
        SetSpellActive(false);

        // === Esperar a inicio de "appear" del player ===
        float appearStartAbs = playerStartTime + Mathf.Max(0.0001f, disappearDuration) + Mathf.Max(0f, holdGoneSeconds);
        float timeToAppearStart = appearStartAbs - Time.time;
        if (timeToAppearStart > 0f) yield return new WaitForSeconds(timeToAppearStart);

        // === Spell vuelve a aparecer ARRIBA, hace fade-in y luego baja ===
        SetSpellActive(true);
        MoveSpellToTop();

        // Asegura que arranca en 0
        SetSpellParamsZeroInstant();

        // Animación 0 -> valores originales (antes de bajar)
        yield return CoFadeSpellParamsFromZeroToOriginal(Mathf.Max(0.0001f, spellFadeInDuration));

        // (Opcional) si quisieras reiniciar también la animación del shader al reaparecer:
        // StartSpellShader();

        float downDur = (spellReturnDuration > 0f) ? spellReturnDuration : spellRiseDuration;
        yield return CoMoveSpell(-spellRiseUnits, Mathf.Max(0.0001f, downDur));

        // Fade out y apagar
        yield return CoFadeSpellParamsToZero(Mathf.Max(0.0001f, spellFadeOutDuration));
        SetSpellActive(false);

        _sequence = null;
    }

    public void ForceVisibleManual()
    {
        if (!skinnedA && !skinnedB) return;

        _mpbPlayer.Clear();
        _mpbPlayer.SetFloat(ID_AutoCycle, 0f);
        _mpbPlayer.SetFloat(ID_Disappear, 0f);

        ApplyBlockToAllMaterials(skinnedA, _mpbPlayer);
        ApplyBlockToAllMaterials(skinnedB, _mpbPlayer);
    }

    private void ApplyPlayerAuto(float startTime)
    {
        if (!skinnedA && !skinnedB)
        {
            Debug.LogError("[MagicManager] Asigna skinnedA (y opcionalmente skinnedB).");
            return;
        }

        Bounds combined;
        bool has = TryGetCombinedBounds(out combined);

        float minY = has ? combined.min.y : 0f;
        float maxY = has ? combined.max.y : 2f;

        _mpbPlayer.Clear();
        _mpbPlayer.SetFloat(ID_BoundsMinY, minY);
        _mpbPlayer.SetFloat(ID_BoundsMaxY, maxY);

        _mpbPlayer.SetFloat(ID_AutoCycle, 1f);
        _mpbPlayer.SetFloat(ID_AutoStartTime, startTime);

        _mpbPlayer.SetFloat(ID_DisappearDuration, Mathf.Max(0.0001f, disappearDuration));
        _mpbPlayer.SetFloat(ID_HoldGone, Mathf.Max(0f, holdGoneSeconds));
        _mpbPlayer.SetFloat(ID_AppearDuration, Mathf.Max(0.0001f, appearDuration));
        _mpbPlayer.SetFloat(ID_AutoLoop, loop ? 1f : 0f);

        ApplyBlockToAllMaterials(skinnedA, _mpbPlayer);
        ApplyBlockToAllMaterials(skinnedB, _mpbPlayer);
    }

    // ---------------- Spell: shader control ----------------

    private void StartSpellShader()
    {
        if (!spellRenderer) return;

        int count = GetSpellMaterialCount();
        for (int i = 0; i < count; i++)
        {
            spellRenderer.GetPropertyBlock(_mpbSpell, i);
            _mpbSpell.SetFloat(ID_AnimStartTime, Time.time);
            spellRenderer.SetPropertyBlock(_mpbSpell, i);
        }
    }

    private void SetSpellParamsZeroInstant()
    {
        if (!spellRenderer) return;

        int count = GetSpellMaterialCount();
        for (int i = 0; i < count; i++)
        {
            spellRenderer.GetPropertyBlock(_mpbSpell, i);
            _mpbSpell.SetFloat(ID_LineWidth, 0f);
            _mpbSpell.SetFloat(ID_EmissiveIntensity, 0f);
            _mpbSpell.SetFloat(ID_BlueEmissiveBoost, 0f);
            _mpbSpell.SetFloat(ID_LightStrength, 0f);
            spellRenderer.SetPropertyBlock(_mpbSpell, i);
        }
    }

    private void RestoreSpellParamsInstant()
    {
        if (!spellRenderer) return;
        CacheSpellOriginalParamsIfNeeded();
        if (!_spellOrigCached) return;

        int count = GetSpellMaterialCount();
        for (int i = 0; i < count; i++)
        {
            spellRenderer.GetPropertyBlock(_mpbSpell, i);
            _mpbSpell.SetFloat(ID_LineWidth, _origLineWidth[i]);
            _mpbSpell.SetFloat(ID_EmissiveIntensity, _origEmissiveIntensity[i]);
            _mpbSpell.SetFloat(ID_BlueEmissiveBoost, _origBlueEmissiveBoost[i]);
            _mpbSpell.SetFloat(ID_LightStrength, _origLightStrength[i]);
            spellRenderer.SetPropertyBlock(_mpbSpell, i);
        }
    }

    private IEnumerator CoFadeSpellParamsToZero(float duration)
    {
        if (!spellRenderer || !_spellOrigCached) yield break;

        int count = GetSpellMaterialCount();
        float t = 0f;

        while (t < duration)
        {
            t += Time.deltaTime;
            float k = Mathf.Clamp01(t / duration);

            for (int i = 0; i < count; i++)
            {
                float lw = Mathf.Lerp(_origLineWidth[i], 0f, k);
                float ei = Mathf.Lerp(_origEmissiveIntensity[i], 0f, k);
                float bb = Mathf.Lerp(_origBlueEmissiveBoost[i], 0f, k);
                float ls = Mathf.Lerp(_origLightStrength[i], 0f, k);

                spellRenderer.GetPropertyBlock(_mpbSpell, i);
                _mpbSpell.SetFloat(ID_LineWidth, lw);
                _mpbSpell.SetFloat(ID_EmissiveIntensity, ei);
                _mpbSpell.SetFloat(ID_BlueEmissiveBoost, bb);
                _mpbSpell.SetFloat(ID_LightStrength, ls);
                spellRenderer.SetPropertyBlock(_mpbSpell, i);
            }

            yield return null;
        }

        SetSpellParamsZeroInstant();
    }

    private IEnumerator CoFadeSpellParamsFromZeroToOriginal(float duration)
    {
        if (!spellRenderer) yield break;
        CacheSpellOriginalParamsIfNeeded();
        if (!_spellOrigCached) yield break;

        int count = GetSpellMaterialCount();
        float t = 0f;

        while (t < duration)
        {
            t += Time.deltaTime;
            float k = Mathf.Clamp01(t / duration);

            for (int i = 0; i < count; i++)
            {
                float lw = Mathf.Lerp(0f, _origLineWidth[i], k);
                float ei = Mathf.Lerp(0f, _origEmissiveIntensity[i], k);
                float bb = Mathf.Lerp(0f, _origBlueEmissiveBoost[i], k);
                float ls = Mathf.Lerp(0f, _origLightStrength[i], k);

                spellRenderer.GetPropertyBlock(_mpbSpell, i);
                _mpbSpell.SetFloat(ID_LineWidth, lw);
                _mpbSpell.SetFloat(ID_EmissiveIntensity, ei);
                _mpbSpell.SetFloat(ID_BlueEmissiveBoost, bb);
                _mpbSpell.SetFloat(ID_LightStrength, ls);
                spellRenderer.SetPropertyBlock(_mpbSpell, i);
            }

            yield return null;
        }

        RestoreSpellParamsInstant();
    }

    // ---------------- Spell: movement/activation ----------------

    private IEnumerator CoMoveSpell(float deltaUpUnits, float duration)
    {
        Transform t = GetSpellTransform();
        if (!t) yield break;

        Vector3 from = spellMoveInLocalSpace ? t.localPosition : t.position;
        Vector3 to   = from + Vector3.up * deltaUpUnits;

        float elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float k = Mathf.Clamp01(elapsed / duration);

            Vector3 p = Vector3.LerpUnclamped(from, to, k);
            if (spellMoveInLocalSpace) t.localPosition = p;
            else t.position = p;

            yield return null;
        }

        if (spellMoveInLocalSpace) t.localPosition = to;
        else t.position = to;
    }

    private void MoveSpellToTop()
    {
        if (!_spellPosCached) return;
        Transform t = GetSpellTransform();
        if (!t) return;

        Vector3 top = _spellStartPos + Vector3.up * spellRiseUnits;
        if (spellMoveInLocalSpace) t.localPosition = top;
        else t.position = top;
    }

    private void ResetSpellToStartPos()
    {
        if (!_spellPosCached) return;
        Transform t = GetSpellTransform();
        if (!t) return;

        if (spellMoveInLocalSpace) t.localPosition = _spellStartPos;
        else t.position = _spellStartPos;
    }

    private void SetSpellActive(bool active)
    {
        GameObject go = GetSpellRootGO();
        if (!go) return;
        if (go.activeSelf != active) go.SetActive(active);
    }

    private Transform GetSpellTransform()
    {
        if (spellGameObject) return spellGameObject.transform;
        if (spellRenderer) return spellRenderer.transform;
        return null;
    }

    private GameObject GetSpellRootGO()
    {
        if (spellGameObject) return spellGameObject;
        if (spellRenderer) return spellRenderer.gameObject;
        return null;
    }

    // ---------------- Spell: timing helpers ----------------

    private float GetSpellWaitBeforeRise()
    {
        if (!spellRenderer) return 0f;

        Material m = null;
        var mats = spellRenderer.sharedMaterials;
        if (mats != null && mats.Length > 0) m = mats[0];
        else m = spellRenderer.sharedMaterial;

        if (!m) return 0f;

        float g1 = GetFloatSafe(m, "_GrowTime1", 1f);
        float g2 = GetFloatSafe(m, "_GrowTime2", g1);
        float g3 = GetFloatSafe(m, "_GrowTime3", g1);
        float g4 = GetFloatSafe(m, "_GrowTime4", g1);

        float growEnd = Mathf.Max(g1, Mathf.Max(g2, Mathf.Max(g3, g4)));

        float blueDelay = GetFloatSafe(m, "_BlueDelay", 0.5f);
        blueDelay = Mathf.Max(0f, blueDelay);

        if (!riseAfterBlueComplete)
            return growEnd;

        return growEnd + blueDelay;
    }

    private int GetSpellMaterialCount()
    {
        if (!spellRenderer) return 0;
        var mats = spellRenderer.sharedMaterials;
        int count = (mats != null) ? mats.Length : 0;
        return Mathf.Max(1, count);
    }

    private void CacheSpellOriginalParamsIfNeeded()
    {
        if (_spellOrigCached) return;
        if (!spellRenderer) return;

        int count = GetSpellMaterialCount();

        _origLineWidth = new float[count];
        _origEmissiveIntensity = new float[count];
        _origBlueEmissiveBoost = new float[count];
        _origLightStrength = new float[count];

        Material[] mats = spellRenderer.sharedMaterials;

        for (int i = 0; i < count; i++)
        {
            Material mm = null;
            if (mats != null && i < mats.Length) mm = mats[i];
            if (!mm) mm = spellRenderer.sharedMaterial;

            _origLineWidth[i] = GetFloatSafe(mm, "_LineWidth", 0.02f);
            _origEmissiveIntensity[i] = GetFloatSafe(mm, "_EmissiveIntensity", 1.0f);
            _origBlueEmissiveBoost[i] = GetFloatSafe(mm, "_BlueEmissiveBoost", 2.0f);
            _origLightStrength[i] = GetFloatSafe(mm, "_LightStrength", 1.0f);
        }

        _spellOrigCached = true;
    }

    private void CacheSpellStartPosIfNeeded()
    {
        if (_spellPosCached) return;

        Transform t = GetSpellTransform();
        if (!t) return;

        _spellStartPos = spellMoveInLocalSpace ? t.localPosition : t.position;
        _spellPosCached = true;
    }

    // ---------------- General helpers ----------------

    private static float GetFloatSafe(Material m, string propName, float fallback)
    {
        if (!m) return fallback;
        return m.HasProperty(propName) ? m.GetFloat(propName) : fallback;
    }

    private void ApplyBlockToAllMaterials(Renderer r, MaterialPropertyBlock block)
    {
        if (!r) return;

        int count = (r.sharedMaterials != null) ? r.sharedMaterials.Length : 0;
        if (count <= 0)
        {
            r.SetPropertyBlock(block);
            return;
        }

        for (int i = 0; i < count; i++)
            r.SetPropertyBlock(block, i);
    }

    private bool TryGetCombinedBounds(out Bounds b)
    {
        b = default;
        bool has = false;

        if (skinnedA)
        {
            b = skinnedA.bounds;
            has = true;
        }

        if (skinnedB)
        {
            if (!has) { b = skinnedB.bounds; has = true; }
            else b.Encapsulate(skinnedB.bounds);
        }

        return has;
    }
}

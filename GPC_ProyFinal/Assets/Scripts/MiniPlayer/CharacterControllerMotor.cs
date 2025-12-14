using UnityEngine;
using UnityEngine.InputSystem;

public class CharacterControllerMotor : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] float walkSpeed = 5f;
    [SerializeField] float sprintSpeed = 8f;
    [SerializeField] float crouchSpeed = 2.5f;

    [Header("Jump & Gravity")]
    [SerializeField] float gravity = -20f;
    [SerializeField] float jumpHeight = 1.5f;

    [Header("Crouch")]
    [SerializeField] float crouchHeight = 1.1f;
    [SerializeField] float crouchLerpSpeed = 10f;
    
    [Header("Rotation")]
    [SerializeField] Transform visualModel;     // arrastra aquí tu mesh/modelo (opcional)
    [SerializeField] float turnSpeed = 12f;     // más alto = gira más rápido

    [Header("Camera Reference")]
    [SerializeField] Transform cameraTransform;
    
    CharacterController cc;

    Vector2 moveInput;
    bool sprintHeld;
    bool crouchHeld;
    bool jumpPressed;

    float verticalVelocity;
    float standHeight;

    private void Awake()
    {
        cc = GetComponent<CharacterController>();
        standHeight = cc.height;
        
        if (visualModel == null) visualModel = transform;
        if (cameraTransform == null && Camera.main != null) cameraTransform = Camera.main.transform;
    }
    
    void Update()
    {
        bool grounded = cc.isGrounded;
        if (grounded && verticalVelocity < 0f) verticalVelocity = -2f;

        float speed = crouchHeld ? crouchSpeed : (sprintHeld ? sprintSpeed : walkSpeed);

        // ===== Movimiento relativo a cámara =====
        Vector3 moveWorld = Vector3.zero;

        if (cameraTransform != null)
        {
            Vector3 camForward = cameraTransform.forward; camForward.y = 0f; camForward.Normalize();
            Vector3 camRight   = cameraTransform.right;   camRight.y = 0f;   camRight.Normalize();

            moveWorld = (camRight * moveInput.x + camForward * moveInput.y);
        }
        else
        {
            // Fallback si no hay cámara asignada
            moveWorld = new Vector3(moveInput.x, 0f, moveInput.y);
        }

        // Rotar el modelo hacia donde te mueves
        if (moveWorld.sqrMagnitude > 0.0001f)
        {
            Quaternion targetRot = Quaternion.LookRotation(moveWorld, Vector3.up);
            visualModel.rotation = Quaternion.Slerp(visualModel.rotation, targetRot, turnSpeed * Time.deltaTime);
        }

        cc.Move(moveWorld.normalized * speed * Time.deltaTime);

        // Salto
        if (jumpPressed && grounded && !crouchHeld)
            verticalVelocity = Mathf.Sqrt(jumpHeight * -2f * gravity);
        jumpPressed = false;

        // Gravedad
        verticalVelocity += gravity * Time.deltaTime;
        cc.Move(Vector3.up * (verticalVelocity * Time.deltaTime));

        // Crouch
        float targetHeight = crouchHeld ? crouchHeight : standHeight;
        cc.height = Mathf.MoveTowards(cc.height, targetHeight, crouchLerpSpeed * Time.deltaTime);
        cc.center = new Vector3(cc.center.x, cc.height * 0.5f, cc.center.z);
    }

    // ===== PlayerInput (Send Messages) =====
    public void OnMove(InputValue value) => moveInput = value.Get<Vector2>();
    public void OnSprint(InputValue value) => sprintHeld = value.isPressed;
    public void OnCrouch(InputValue value) => crouchHeld = value.isPressed;
    public void OnJump(InputValue value) { if (value.isPressed) jumpPressed = true; }
    public void OnLook(InputValue value) { } // cámara la lleva Cinemachine
}

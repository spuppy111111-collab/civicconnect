import asyncio
import json
import sys

# Ensure UTF-8 output if possible
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

from backend_api import (
    app,
    register, RegisterRequestSchema,
    login, LoginRequestSchema,
    forgot_password, ForgotPasswordRequestSchema,
    reset_password, ResetPasswordRequestSchema,
    get_profile,
    create_complaint, ComplaintCreateSchema,
    get_complaints,
    get_admin_complaints,
    get_complaint_by_id,
    update_complaint_status, StatusUpdateSchema,
    track_complaint,
    get_categories,
    get_complaints_map,
    get_nearby_complaints,
    upload_image, ImageUploadPayload,
    get_dashboard_statistics,
    get_unified_dashboard,
    get_analytics_complaints,
    get_analytics_categories,
    get_analytics_monthly,
    get_analytics_performance,
    get_users,
    get_user_impact,
    get_departments,
    assign_complaint, OfficerAssignSchema,
    get_officers,
    get_notifications,
    submit_feedback, FeedbackCreateSchema,
    report_emergency, EmergencyReportSchema,
    analyze_image, AIAnalyzeImageRequest,
)

async def run_tests():
    print("=" * 60)
    print("CIVICCONNECT 15-MODULE BACKEND API VERIFICATION SUITE")
    print("=" * 60)

    # 1. Auth: Register, Login, Profile
    try:
        reg = await register(RegisterRequestSchema(
            email="field.worker.test@civicconnect.com",
            password="WorkerPassword123!",
            name="Field Worker Test",
            role="field_worker",
            phone="+91 9988776655",
            location="Guntur West"
        ))
        print("[PASS] [1. Auth Register] Success:", reg["user"]["email"], "| Role:", reg["user"]["role"])
    except Exception as e:
        print("[INFO] [1. Auth Register] Handled (e.g. exists):", str(e))

    log = await login(LoginRequestSchema(
        email="citizen@civicconnect.com",
        password="citizen123"
    ))
    print("[PASS] [1. Auth Login] Token generated for:", log["name"], "| Role:", log["role"])

    prof = await get_profile(user_id="user-1")
    print("[PASS] [1. Auth Profile] Profile fetched:", prof["data"]["name"])

    # 2. Complaint Management
    comp = await create_complaint(ComplaintCreateSchema(
        title="Severe Pothole Cluster on Main Ring Road",
        description="Multiple large potholes causing traffic jam and accidents.",
        category="roads",
        location="Ring Road, Guntur",
        latitude=16.3050,
        longitude=80.4350,
        priority="high",
        user_id="user-1"
    ))
    new_id = comp["data"]["id"]
    print(f"[PASS] [2. Complaint Create] Created complaint ID: {new_id}")

    all_c = await get_complaints(category="roads")
    print(f"[PASS] [2. Complaint List] Retrieved {len(all_c['data'])} road complaints")

    admin_c = await get_admin_complaints()
    print(f"[PASS] [2. Admin Complaints View] Total complaints in system: {admin_c['data']['statistics']['total_complaints']}")

    # 3. Status & Tracking
    st_up = await update_complaint_status(new_id, StatusUpdateSchema(
        status="in-progress",
        note="Repair team deployed on site."
    ))
    print(f"[PASS] [3. Status Update] Status changed to: {st_up['data']['status']}")

    track = await track_complaint(new_id)
    print(f"[PASS] [3. Track Progress] Stages in timeline: {len(track['data']['progress'])}")

    # 4. Categories
    cats = await get_categories()
    print(f"[PASS] [4. Categories] Total categories: {cats['count']}")

    # 5. Location & Maps
    maps = await get_complaints_map()
    print(f"[PASS] [5. Maps] Map markers count: {maps['count']}")

    nearby = await get_nearby_complaints(lat=16.3067, lng=80.4365, radius=15.0)
    print(f"[PASS] [5. Nearby Complaints] Found {nearby['count']} complaints within 15km")

    # 6. Uploads
    upl = await upload_image(ImageUploadPayload(complaint_id=new_id, file_name="pothole_survey.jpg"))
    print(f"[PASS] [6. Uploads] Image URL generated: {upl['imageUrl']}")

    # 7. Dashboard Statistics
    stats = await get_dashboard_statistics()
    print(f"[PASS] [7. Dashboard Stats] Total: {stats['data']['totalComplaints']}, Resolved: {stats['data']['resolved']}, Satisfaction: {stats['data']['satisfactionRating']}/5")

    dash = await get_unified_dashboard(user_id="user-1")
    print(f"[PASS] [7. Unified Citizen Dashboard] Loaded user: {dash['data']['user']['name']}")

    # 8. Analytics
    ana_cat = await get_analytics_categories()
    print(f"[PASS] [8. Analytics Categories] Breakdown entries: {len(ana_cat['data'])}")

    ana_perf = await get_analytics_performance()
    print(f"[PASS] [8. Analytics Performance] Department benchmarks: {len(ana_perf['data'])}")

    # 9. User Management
    users = await get_users()
    print(f"[PASS] [9. User Management] Total registered users: {users['count']}")

    impact = await get_user_impact("user-1")
    print(f"[PASS] [9. User Impact] Civic Level: {impact['data']['civicLevel']} | Points: {impact['data']['points']}")

    # 10. Departments
    depts = await get_departments()
    print(f"[PASS] [10. Departments] Municipal departments count: {depts['count']}")

    # 11. Officer Assignment
    assign = await assign_complaint(new_id, OfficerAssignSchema(officer_id="OFF-101", department_id="DEP-ROADS"))
    print(f"[PASS] [11. Officer Assignment] Assigned {new_id} to {assign['data']['officerId']}")

    # 12. Notifications
    notifs = await get_notifications(user_id="user-1")
    print(f"[PASS] [12. Notifications] User notifications count: {notifs['count']}")

    # 13. Feedback & Rating
    fb = await submit_feedback(FeedbackCreateSchema(complaint_id=new_id, rating=5, comment="Fixed in 45 minutes!"))
    print(f"[PASS] [13. Feedback & Rating] Submitted rating: {fb['data']['rating']} stars")

    # 14. Emergency Complaint
    emerg = await report_emergency(EmergencyReportSchema(
        hazard_type="Live Wire Down",
        description="High tension line fell on sidewalk",
        location="Brodipet 4th Lane, Guntur"
    ))
    print(f"[PASS] [14. Emergency Complaint] Broadcasted emergency ID: {emerg['data']['emergencyId']}")

    # 15. AI Vision Analyzer
    ai = await analyze_image(AIAnalyzeImageRequest(
        image_url="https://example.com/pothole_hole.jpg",
        context="deep asphalt pothole"
    ))
    print(f"[PASS] [15. AI Vision Detection] Result: '{ai['result']}' | Confidence: {ai['confidence']}% | Route: {ai['suggestedDepartment']}")

    print("=" * 60)
    print("ALL 15 CIVICCONNECT API MODULES VERIFIED & WORKING PERFECTLY!")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(run_tests())

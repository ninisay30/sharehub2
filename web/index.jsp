<%-- 
    Document   : index
    Created on : Dec 31, 2025, 5:43:13 PM
    Author     : Asus
--%>

<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShareHub</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260521a">

</head>
<body>

<header>
    <h1>ShareHub</h1>
    <div>
        <a href="login.jsp">Log in</a>
        <a href="register.jsp">Register</a>
    </div>
</header>

<div class="landing-container">

    <!-- HERO SECTION -->
    <section class="hero">
        <div class="hero-layout">
            <div class="hero-copy">
                <h1>
                    Give items a second life.
                </h1>

                <p class="hero-text">
                    Help fellow UMT students through sharing and reuse.
                    ShareHub makes giving and requesting useful items simple, practical, and sustainability-focused.
                </p>

                <div class="hero-buttons">
                    <a href="login.jsp" class="primary-btn hero-btn">Donate</a>
                    <a href="login.jsp" class="primary-btn hero-btn">Request</a>
                </div>
            </div>

            <div class="hero-visual" aria-hidden="true">
                <div class="hero-illustration">
                    <svg class="hero-illustration-svg" viewBox="0 0 360 190" xmlns="http://www.w3.org/2000/svg">
                        <rect x="0" y="0" width="360" height="190" rx="14" fill="#f4f8f4"/>

                        <ellipse cx="55" cy="162" rx="26" ry="6" fill="#d7e6d7"/>
                        <ellipse cx="305" cy="162" rx="26" ry="6" fill="#d7e6d7"/>

                        <rect x="33" y="60" width="20" height="58" rx="8" fill="#c9d8ef"/>
                        <rect x="30" y="116" width="12" height="40" rx="4" fill="#3b3b3f"/>
                        <rect x="44" y="116" width="12" height="40" rx="4" fill="#3b3b3f"/>
                        <circle cx="43" cy="44" r="11" fill="#f2d4bf"/>
                        <rect x="56" y="74" width="38" height="12" rx="6" fill="#bce6e2"/>
                        <rect x="79" y="80" width="18" height="8" rx="3" fill="#f2d4bf"/>
                        <rect x="30" y="154" width="30" height="6" rx="3" fill="#5d8d68"/>

                        <rect x="307" y="58" width="20" height="60" rx="8" fill="#cfd2e8"/>
                        <rect x="304" y="116" width="12" height="40" rx="4" fill="#3b3b3f"/>
                        <rect x="318" y="116" width="12" height="40" rx="4" fill="#3b3b3f"/>
                        <circle cx="317" cy="42" r="11" fill="#f2d4bf"/>
                        <path d="M305 34 Q317 18 328 34" fill="#3b3b3f"/>
                        <rect x="266" y="72" width="42" height="12" rx="6" fill="#f2d4bf"/>
                        <rect x="262" y="82" width="16" height="8" rx="3" fill="#f2d4bf"/>
                        <rect x="302" y="154" width="30" height="6" rx="3" fill="#5d8d68"/>

                        <path d="M118 63
                                 C118 48, 136 43, 145 56
                                 C154 43, 172 48, 172 63
                                 C172 79, 153 88, 145 99
                                 C137 88, 118 79, 118 63Z" fill="#4f8666"/>

                        <g>
                            <rect x="188" y="100" width="46" height="38" fill="#e0b074" stroke="#b78145" stroke-width="2"/>
                            <rect x="192" y="80" width="38" height="22" fill="#e8be87" stroke="#b78145" stroke-width="2"/>
                            <line x1="211" y1="80" x2="211" y2="102" stroke="#b78145" stroke-width="2"/>
                        </g>

                        <g>
                            <rect x="236" y="94" width="46" height="44" fill="#d9a86d" stroke="#b78145" stroke-width="2"/>
                            <rect x="240" y="72" width="38" height="22" fill="#e8be87" stroke="#b78145" stroke-width="2"/>
                            <line x1="259" y1="72" x2="259" y2="94" stroke="#b78145" stroke-width="2"/>
                        </g>

                        <g>
                            <rect x="142" y="114" width="44" height="24" fill="#e7bb84" stroke="#b78145" stroke-width="2"/>
                            <rect x="153" y="96" width="24" height="18" transform="rotate(38 165 105)" fill="#e7bb84" stroke="#b78145" stroke-width="2"/>
                        </g>
                    </svg>
                </div>
            </div>
        </div>
    </section>

    <hr class="divider">

    <!-- HOW IT WORKS -->
    <section class="how-it-works">
        <h2>How it works</h2>

        <div class="steps">

            <div class="step-card">
                <span class="step-icon"><i class="bi bi-box-seam" aria-hidden="true"></i></span>
                <h3>Post a Donation</h3>
                <p>
                    Share an item you no longer need. Your post goes to admin review before it appears.
                </p>
            </div>

            <div class="step-card">
                <span class="step-icon"><i class="bi bi-clipboard-check" aria-hidden="true"></i></span>
                <h3>Admin Review &amp; Publish</h3>
                <p>
                    Admin checks donation posts and item requests, then approves or rejects them with status updates.
                </p>
            </div>

            <div class="step-card">
                <span class="step-icon"><i class="bi bi-calendar-check" aria-hidden="true"></i></span>
                <h3>Request &amp; Schedule Pickup</h3>
                <p>
                    Students request available items. If selected, the donor sets pickup place and time, and both users get notifications.
                </p>
            </div>

            <div class="step-card">
                <span class="step-icon"><i class="bi bi-check2-circle" aria-hidden="true"></i></span>
                <h3>Confirm Handover</h3>
                <p>
                    Requester marks item received, then donor confirms handover to complete the request and donation.
                </p>
            </div>

        </div>
    </section>

    <hr class="divider">

    <section class="why-sharehub">
        <h2>Why ShareHub?</h2>
        <div class="why-grid">
            <article class="why-card">
                <div class="why-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M6 14c0-4 2.5-7.5 6-9 3.5 1.5 6 5 6 9a6 6 0 0 1-12 0z"></path>
                        <path d="M12 5v15"></path>
                    </svg>
                </div>
                <h3>Sustainable</h3>
                <p>Reduce waste by giving usable items a second life through sharing and reuse.</p>
            </article>

            <article class="why-card">
                <div class="why-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="8" cy="8" r="3"></circle>
                        <circle cx="16" cy="8" r="3"></circle>
                        <path d="M3 19c0-2.2 2.2-4 5-4s5 1.8 5 4"></path>
                        <path d="M11 19c.2-1.6 1.9-3 4-3 2.4 0 4.5 1.6 5 3"></path>
                    </svg>
                </div>
                <h3>Community-Based</h3>
                <p>Support fellow UMT students by making useful items accessible within the campus community.</p>
            </article>

            <article class="why-card">
                <div class="why-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M12 21s-6-4.5-6-10a6 6 0 1 1 12 0c0 5.5-6 10-6 10z"></path>
                        <path d="M12 9v4"></path>
                        <path d="M12 9h3"></path>
                    </svg>
                </div>
                <h3>Easy Pickup</h3>
                <p>Coordinate pickup time and location in one flow for smooth and organized handovers.</p>
            </article>
        </div>
    </section>

</div>

<footer>
    &copy; 2025 ShareHub &ndash; Student Donation Channel
</footer>

</body>

</html>


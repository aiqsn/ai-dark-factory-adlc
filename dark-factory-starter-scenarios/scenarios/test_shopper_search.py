# Hidden holdout scenarios: written as a shopper would use the product, not as the unit tests do.
# The agent never sees this repository, so it can't tune its code to pass these.


def names(response):
    return [p["name"] for p in response.json()["results"]]


def test_shopper_finds_running_gear(app):
    r = app.get("/api/search", q="running")
    assert r.status_code == 200
    found = names(r)
    assert found, "a common word must find something"
    assert all("running" in n.lower() for n in found), "every result must be about running"


def test_shopper_typing_in_capitals_gets_the_same_results(app):
    assert names(app.get("/api/search", q="Running Shoes")) == names(app.get("/api/search", q="running shoes"))


def test_stray_spaces_do_not_break_search(app):
    assert names(app.get("/api/search", q="  waterproof   ")) == names(app.get("/api/search", q="waterproof"))


def test_two_words_narrow_the_results(app):
    broad = names(app.get("/api/search", q="running"))
    narrow = names(app.get("/api/search", q="running shoes"))
    assert narrow and set(narrow) <= set(broad) and len(narrow) < len(broad)


def test_nothing_matches_is_an_empty_list_not_an_error(app):
    r = app.get("/api/search", q="snowboard")
    assert r.status_code == 200
    assert r.json()["results"] == []


def test_empty_search_explains_what_is_wrong(app):
    r = app.get("/api/search", q="")
    assert r.status_code == 400
    assert "missing q" in r.json().get("error", "")


def test_search_answers_quickly(app):
    r = app.get("/api/search", q="jacket")
    assert r.elapsed.total_seconds() < 1.0


def test_health_and_version_stay_available(app):
    assert app.get("/healthz").text.strip() == "ok"
    assert app.get("/version").text.strip(), "deploy probes need /version"

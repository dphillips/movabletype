/*
 * Do not edit this file manually.
 * This file is generated by "build/build-api".
 */
(function(window) {


window.MT.API.prototype.authorization = function() {
    return this.request.apply(this, [
        'GET',
        '/authorization'
    ].concat(Array.prototype.slice.call(arguments, 0)));
}

window.MT.API.prototype.authentication = function() {
    return this.request.apply(this, [
        'POST',
        '/authentication'
    ].concat(Array.prototype.slice.call(arguments, 0)));
}

window.MT.API.prototype.token = function() {
    return this.request.apply(this, [
        'POST',
        '/token'
    ].concat(Array.prototype.slice.call(arguments, 0)));
}

window.MT.API.prototype.getUser = function(user_id) {
    return this.request.apply(this, [
        'GET',
        this.bindEndpointParams('/users/:user_id', {
            user_id: user_id
        })
    ].concat(Array.prototype.slice.call(arguments, 1)));
}

window.MT.API.prototype.listBlogs = function() {
    return this.request.apply(this, [
        'GET',
        '/users/{user_id}/sites'
    ].concat(Array.prototype.slice.call(arguments, 0)));
}

window.MT.API.prototype.listEntries = function(site_id) {
    return this.request.apply(this, [
        'GET',
        this.bindEndpointParams('/sites/:site_id/entries', {
            site_id: site_id
        })
    ].concat(Array.prototype.slice.call(arguments, 1)));
}


})(window);
